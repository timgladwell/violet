// DRAFT — local consideration only, not for staging or production (#57).
// Parked outside site/functions/ so no Pages build, preview or production,
// can serve it. Going live means moving it to site/functions/mcp.js.
//
// A read-only MCP server at /mcp, as a Cloudflare Pages Function: stateless
// Streamable HTTP, one JSON-RPC message per POST, JSON responses (no SSE).
// It holds no clinic data of its own. Every answer is read from the JSON-LD
// that baseof.html already renders into the home page, so services and
// prices stay in sync with the site by construction, and maintenance mode
// (which omits the JSON-LD) makes the tools report "unavailable" for free.
//
// No dependencies: the official SDK needs a bundler and Durable Objects for
// sessions, neither of which a three-tool read-only server uses.

const PROTOCOL_VERSIONS = ['2025-11-25', '2025-06-18', '2025-03-26'];

const INSTRUCTIONS =
  'Information about Ontario Menopause Clinic, a virtual perimenopause and ' +
  'menopause practice. Factual clinic information only, never medical advice. ' +
  'Booking happens on the website; this server cannot book or see appointments.';

const TOOLS = [
  {
    name: 'get_clinic_overview',
    title: 'Clinic overview',
    description: 'Who the clinic is, the practitioner, where care is offered, and the booking page URL.',
    inputSchema: { type: 'object', properties: {}, additionalProperties: false },
    annotations: { readOnlyHint: true, openWorldHint: false },
  },
  {
    name: 'list_services',
    title: 'Services and prices',
    description: 'Every service the clinic offers, with duration (ISO 8601) and price in CAD.',
    inputSchema: { type: 'object', properties: {}, additionalProperties: false },
    annotations: { readOnlyHint: true, openWorldHint: false },
  },
  {
    name: 'check_eligibility',
    title: 'Check eligibility by location',
    description:
      'Whether someone can be seen, given the Canadian province or territory they will be ' +
      'physically located in during the visit. Licensing allows Ontario only.',
    inputSchema: {
      type: 'object',
      properties: {
        province: { type: 'string', maxLength: 64, description: 'Province or territory name or code, e.g. "Ontario" or "ON".' },
      },
      required: ['province'],
      additionalProperties: false,
    },
    annotations: { readOnlyHint: true, openWorldHint: false },
  },
];

export async function onRequest({ request, env }) {
  if (request.method !== 'POST') {
    // Stateless: no server-initiated stream to open with GET, no session to DELETE.
    return new Response(null, { status: 405, headers: { Allow: 'POST' } });
  }
  // The spec requires Origin validation against DNS rebinding; a browser page
  // on another site has no business calling this.
  const origin = request.headers.get('Origin');
  if (origin && origin !== new URL(request.url).origin) {
    return new Response(null, { status: 403 });
  }

  let msg;
  try {
    msg = await request.json();
  } catch {
    return rpcError(null, -32700, 'Parse error');
  }
  if (!msg || typeof msg !== 'object' || Array.isArray(msg) || msg.jsonrpc !== '2.0' || typeof msg.method !== 'string') {
    return rpcError(msg?.id ?? null, -32600, 'Invalid Request');
  }
  // Notifications (no id) get 202 and no body.
  if (msg.id === undefined) return new Response(null, { status: 202 });

  switch (msg.method) {
    case 'initialize': {
      const asked = msg.params?.protocolVersion;
      return rpcResult(msg.id, {
        protocolVersion: PROTOCOL_VERSIONS.includes(asked) ? asked : PROTOCOL_VERSIONS[0],
        capabilities: { tools: {} },
        serverInfo: { name: 'ontario-menopause-clinic', title: 'Ontario Menopause Clinic', version: '0.1.0' },
        instructions: INSTRUCTIONS,
      });
    }
    case 'ping':
      return rpcResult(msg.id, {});
    case 'tools/list':
      return rpcResult(msg.id, { tools: TOOLS });
    case 'tools/call':
      if (!TOOLS.some((t) => t.name === msg.params?.name)) return rpcError(msg.id, -32602, 'Unknown tool');
      return rpcResult(msg.id, await callTool(msg.params, request, env));
    default:
      return rpcError(msg.id, -32601, 'Method not found');
  }
}

async function callTool({ name, arguments: args = {} }, request, env) {
  const site = await readJsonLd(request, env);
  if (!site) return toolError('Clinic information is temporarily unavailable. Please try again later.');
  const bookingPage = new URL('/book/', site.url).href;

  switch (name) {
    case 'get_clinic_overview':
      return toolResult({
        name: site.name,
        description: site.description,
        website: site.url,
        bookingPage,
        email: site.email || undefined,
        practitioner: {
          name: site.employee?.name,
          credentials: site.employee?.honorificSuffix,
          role: site.employee?.jobTitle,
          summary: site.employee?.description,
        },
        areaServed: site.areaServed?.name,
        careDelivery: 'Virtual (secure video)',
        firstStep: 'A free 15-minute Discovery Call, booked on the website.',
      });
    case 'list_services':
      return toolResult({
        currency: 'CAD',
        bookingPage,
        services: (site.hasOfferCatalog?.itemListElement ?? []).map((offer) => ({
          name: offer.itemOffered?.name,
          description: offer.itemOffered?.description,
          duration: offer.itemOffered?.duration,
          price: offer.price ?? undefined,
          minPrice: offer.priceSpecification?.minPrice ?? undefined,
        })),
      });
    case 'check_eligibility': {
      if (typeof args.province !== 'string' || args.province.length > 64) {
        return toolError('province must be a string of at most 64 characters.');
      }
      const eligible = ['ontario', 'on'].includes(args.province.trim().toLowerCase());
      return toolResult({
        eligible,
        reason: eligible
          ? 'The practitioner is licensed to treat patients physically located in Ontario.'
          : 'The practitioner is licensed by the College of Nurses of Ontario and can only see patients ' +
            'physically located in Ontario at the time of the visit.',
        bookingPage: eligible ? bookingPage : undefined,
      });
    }
  }
}

// shortcut: regex over our own build output, not an HTML parser. It depends on
// baseof.html rendering exactly one unminified ld+json block; switch to a
// Hugo-emitted JSON output format if the site is ever minified.
async function readJsonLd(request, env) {
  const res = await env.ASSETS.fetch(new URL('/', request.url));
  if (!res.ok) return null;
  const match = (await res.text()).match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/);
  if (!match) return null;
  try {
    return JSON.parse(match[1]);
  } catch {
    return null;
  }
}

const toolResult = (data) => ({
  content: [{ type: 'text', text: JSON.stringify(data) }],
  structuredContent: data,
});

const toolError = (text) => ({ content: [{ type: 'text', text }], isError: true });

const json = (body) => new Response(JSON.stringify(body), { headers: { 'Content-Type': 'application/json' } });
const rpcResult = (id, result) => json({ jsonrpc: '2.0', id, result });
const rpcError = (id, code, message) => json({ jsonrpc: '2.0', id, error: { code, message } });
