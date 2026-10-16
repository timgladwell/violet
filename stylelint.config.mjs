/** @type {import('stylelint').Config} */
export default {
  // Correctness rules only. stylelint-config-standard's formatting rules are #160.
  extends: ['stylelint-config-recommended'],
  // Lets template <style> blocks resolve var()s defined in main.css.
  referenceFiles: ['site/assets/css/main.css'],
  overrides: [{ files: ['**/*.html'], customSyntax: 'postcss-html' }],
  rules: {
    // Undefined var()s compute to `unset` silently (#157).
    'no-unknown-custom-properties': true,
    // Flags any lower-specificity selector after a higher one, even across
    // unrelated components - it would force ordering the file by specificity
    // rather than grouping by component.
    'no-descending-specificity': null,
  },
};
