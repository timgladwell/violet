// DRAFT self-check for drafts/mcp-endpoint/mcp.js (#57). Builds the real site with
// Hugo and serves its output as the Pages ASSETS binding, so the tools read the
// same JSON-LD production would. Run from the repo root: node --test drafts/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { onRequest } from './mcp.js';

function build(environment) {
  const out = mkdtempSync(join(tmpdir(), 'violet-mcp-'));
  execFileSync('hugo', ['build', '--source', 'site', '--environment', environment, '--destination', out, '--logLevel', 'error']);
  return { fetch: async (url) => new Response(readFileSync(join(out, new URL(url).pathname, 'index.html'))) };
}

const ASSETS = build('development');
const MAINTENANCE = build('production');

async function rpc(body, { env = { ASSETS }, headers = {} } = {}) {
  const res = await onRequest({
    env,
    request: new Request('https://ontariomenopauseclinic.ca/mcp', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...headers },
      body: typeof body === 'string' ? body : JSON.stringify(body),
    }),
  });
  return { status: res.status, body: res.status === 200 ? await res.json() : null };
}

const call = (name, args, opts) => rpc({ jsonrpc: '2.0', id: 1, method: 'tools/call', params: { name, arguments: args } }, opts);

test('initialize negotiates a supported protocol version', async () => {
  const { body } = await rpc({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18' } });
  assert.equal(body.result.protocolVersion, '2025-06-18');
  assert.deepEqual(body.result.capabilities, { tools: {} });
});

test('notifications get 202 with no body', async () => {
  assert.equal((await rpc({ jsonrpc: '2.0', method: 'notifications/initialized' })).status, 202);
});

test('list_services returns every offer from the JSON-LD', async () => {
  const { services } = (await call('list_services', {})).body.result.structuredContent;
  assert.equal(services.length, 7);
  assert.deepEqual(services[0], {
    name: 'Discovery Call',
    description: services[0].description,
    duration: 'PT15M',
    price: '0.00',
  });
  assert.equal(services.at(-1).minPrice, '40.00');
});

test('check_eligibility is Ontario only', async () => {
  for (const [province, eligible] of [['Ontario', true], [' on ', true], ['BC', false], ['Quebec', false]]) {
    assert.equal((await call('check_eligibility', { province })).body.result.structuredContent.eligible, eligible, province);
  }
  assert.equal((await call('check_eligibility', { province: 'x'.repeat(65) })).body.result.isError, true);
  assert.equal((await call('check_eligibility', {})).body.result.isError, true);
});

test('maintenance mode reports unavailable rather than stale data', async () => {
  assert.equal((await call('list_services', {}, { env: { ASSETS: MAINTENANCE } })).body.result.isError, true);
});

test('protocol errors', async () => {
  assert.equal((await call('book_appointment', {})).body.error.code, -32602);
  assert.equal((await rpc('{not json')).body.error.code, -32700);
  assert.equal((await rpc([{ jsonrpc: '2.0', id: 1, method: 'ping' }])).body.error.code, -32600);
  assert.equal((await rpc({ jsonrpc: '2.0', id: 1, method: 'ping' }, { headers: { Origin: 'https://evil.example' } })).status, 403);
});
