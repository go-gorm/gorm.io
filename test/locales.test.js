'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const test = require('node:test');

// Use Hexo's own YAML parser and i18n implementation, including non-hoisted installs.
const requireFromHexo = createRequire(require.resolve('hexo/package.json'));
const yaml = requireFromHexo('js-yaml');
const I18n = requireFromHexo('hexo-i18n');
const root = path.resolve(__dirname, '..');
const readYaml = file => yaml.load(fs.readFileSync(path.join(root, file), 'utf8'));
const languages = readYaml('pages/_data/languages.yml');
const themeDir = path.join(root, 'themes/navy/languages');
const localeDirs = fs.readdirSync(path.join(root, 'pages'), { withFileTypes: true })
  .filter(entry => entry.isDirectory() && /^[a-z]{2}_[A-Z]{2}$/.test(entry.name))
  .map(entry => entry.name);

test('every published locale has complete language and Crowdin metadata', () => {
  for (const locale of localeDirs) {
    const metadata = languages[locale];
    assert.ok(metadata, `Missing language metadata for ${locale}`);
    for (const key of ['name', 'disqus_lang', 'crowdin']) {
      assert.equal(typeof metadata[key], 'string', `${locale}.${key} must be a string`);
      assert.ok(metadata[key].trim(), `${locale}.${key} must not be empty`);
    }
    assert.ok(fs.existsSync(path.join(themeDir, `${locale}.yml`)), `Missing UI translations for ${locale}`);
  }
});

for (const file of fs.readdirSync(themeDir).filter(file => file.endsWith('.yml'))) {
  test(`Hexo can load UI translations from ${file}`, () => {
    const locale = path.basename(file, '.yml');
    assert.ok(languages[locale], `Missing language metadata for ${locale}`);
    const translations = readYaml(`themes/navy/languages/${file}`);
    const i18n = new I18n({ languages: [locale] });
    assert.doesNotThrow(() => i18n.set(locale, translations), `${file} contains invalid translation values`);
    assert.equal(typeof i18n.__(locale)('menu.docs'), 'string');
  });
}
