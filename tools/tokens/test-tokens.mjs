// Regression check: the pipeline must reproduce test/tonic-tokens.json for the six reference seeds.
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildReference, referenceSeeds } from './gen-tokens.mjs';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const expected = JSON.parse(readFileSync(resolve(ROOT, 'test/tonic-tokens.json'), 'utf8'));

let failures = 0;
for (const [key, hex] of Object.entries(referenceSeeds)) {
  const actual = buildReference(hex);
  for (const mode of ['dark', 'light']) {
    const a = actual[mode];
    const e = expected[key][mode];
    for (const role of Object.keys(e)) {
      if (role === 'sem') continue;
      if (a[role] !== e[role]) { failures++; console.error(`${key}.${mode}.${role}: ${a[role]} != ${e[role]}`); }
    }
    for (const [name, tones] of Object.entries(e.sem)) {
      for (const [tone, value] of Object.entries(tones)) {
        const got = a.sem[name]?.[tone];
        if (got !== value) { failures++; console.error(`${key}.${mode}.sem.${name}.${tone}: ${got} != ${value}`); }
      }
    }
  }
}

if (failures) {
  console.error(`${failures} token(s) differ from test/tonic-tokens.json`);
  process.exit(1);
}
console.log(`OK: ${Object.keys(referenceSeeds).length} reference seeds match test/tonic-tokens.json`);
