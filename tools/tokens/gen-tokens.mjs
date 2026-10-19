// Tonic token pipeline.
// Generates Tonic/Theme/Palettes.generated.lua and the shape/shadow textures in Tonic/Media/Textures.
// Usage: node gen-tokens.mjs            (writes the outputs)
//        node gen-tokens.mjs --json     (prints the reference-format JSON for the six reference seeds)
import {
  argbFromHex, hexFromArgb, Hct, SchemeTonalSpot, MaterialDynamicColors as M, Blend, TonalPalette,
} from '@material/material-color-utilities';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const CONTRAST = 0;
const MIN_SEMANTIC_CHROMA = 48;

// Class seeds, keyed by the classFile returned by UnitClass("player").
// DEFAULT is used when the class is unknown (and as the brand preview).
export const classSeeds = {
  WARRIOR: '#C69B6D', PALADIN: '#F48CBA', HUNTER: '#AAD372', ROGUE: '#FFF468',
  PRIEST: '#FFFFFF', DEATHKNIGHT: '#C41E3A', SHAMAN: '#0070DD', MAGE: '#3FC7EB',
  WARLOCK: '#8788EE', MONK: '#00FF98', DRUID: '#FF7C0A', DEMONHUNTER: '#A330C9',
  EVOKER: '#33937F', DEFAULT: '#6750A4',
};

// The six seeds in test/tonic-tokens.json (Italian keys, as in the reference).
export const referenceSeeds = {
  mago: '#3FC7EB', paladino: '#F48CBA', druido: '#FF7C0A',
  cavaliere: '#C41E3A', evocatore: '#33937F', stregone: '#8788EE',
};

export const roles = ['primary','onPrimary','primaryContainer','onPrimaryContainer','secondary','onSecondary',
  'secondaryContainer','onSecondaryContainer','tertiary','onTertiary','tertiaryContainer','onTertiaryContainer',
  'error','onError','errorContainer','onErrorContainer','surface','surfaceDim','surfaceContainerLowest',
  'surfaceContainerLow','surfaceContainer','surfaceContainerHigh','surfaceContainerHighest','onSurface',
  'onSurfaceVariant','outline','outlineVariant','inverseSurface','inverseOnSurface','inversePrimary','scrim'];

// Extra roles emitted in Lua only (not part of the reference JSON).
const luaExtraRoles = ['surfaceBright', 'surfaceVariant', 'surfaceTint', 'shadow'];

export const semantic = {
  salute: '#3FBF3F', mana: '#2F7FE6', ira: '#E03A2F', energia: '#F2D21B',
  ostile: '#E5484D', gilda: '#40FF40', gruppo: '#AAAAFF', sussurro: '#FF80FF',
  comune: '#9D9D9D', noncomune: '#1EFF00', raro: '#0070DD', epico: '#A335EE', leggendario: '#FF8000',
};

// Lua identifiers for the semantic colors.
const semanticLuaKeys = {
  salute: 'health', mana: 'mana', ira: 'rage', energia: 'energy', ostile: 'hostile',
  gilda: 'chatGuild', gruppo: 'chatParty', sussurro: 'chatWhisper',
  comune: 'qualityCommon', noncomune: 'qualityUncommon', raro: 'qualityRare',
  epico: 'qualityEpic', leggendario: 'qualityLegendary',
};

// Design decision: common quality is neutral, without tint (neutral palette of the scheme).
const NEUTRAL_SEMANTIC = new Set(['comune']);

// Open decision (CLAUDE.md): with warm seeds the harmonized health drifts to yellow-green.
// Add 'salute' here to keep its base hue.
const HARMONIZE_EXCLUDE = new Set([]);

const tones = (pal, dark) => dark
  ? { color: pal.tone(80), bar: pal.tone(70), container: pal.tone(30), onContainer: pal.tone(90) }
  : { color: pal.tone(40), bar: pal.tone(50), container: pal.tone(90), onContainer: pal.tone(10) };

const mapHex = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, hexFromArgb(v)]));

function semanticPalette(baseHex, src, exclude) {
  const base = argbFromHex(baseHex);
  const harm = exclude ? base : Blend.harmonize(base, src);
  const hct = Hct.fromInt(harm);
  return { harm, pal: TonalPalette.fromHueAndChroma(hct.hue, Math.max(hct.chroma, MIN_SEMANTIC_CHROMA)) };
}

/** Reference-format tokens for one seed (identical to the original script output). */
export function buildReference(hex) {
  const src = argbFromHex(hex);
  const out = { seed: hex };
  for (const dark of [true, false]) {
    const s = new SchemeTonalSpot(Hct.fromInt(src), dark, CONTRAST);
    const t = {};
    for (const r of roles) t[r] = hexFromArgb(M[r].getArgb(s));
    const sem = {};
    for (const [n, h] of Object.entries(semantic)) {
      const { harm, pal } = semanticPalette(h, src, false);
      sem[n] = mapHex(tones(pal, dark));
      sem[n].harmonized = hexFromArgb(harm);
    }
    t.sem = sem;
    out[dark ? 'dark' : 'light'] = t;
  }
  return out;
}

/** Tokens as emitted in Lua: argb ints, design decisions applied. */
function buildLua(hex) {
  const src = argbFromHex(hex);
  const out = { seed: hex.slice(1).toUpperCase() };
  for (const dark of [true, false]) {
    const s = new SchemeTonalSpot(Hct.fromInt(src), dark, CONTRAST);
    const r = {};
    for (const role of [...roles, ...luaExtraRoles]) r[role] = M[role].getArgb(s);
    const sem = {};
    for (const [n, h] of Object.entries(semantic)) {
      const pal = NEUTRAL_SEMANTIC.has(n) ? s.neutralPalette : semanticPalette(h, src, HARMONIZE_EXCLUDE.has(n)).pal;
      sem[semanticLuaKeys[n]] = tones(pal, dark);
    }
    out[dark ? 'dark' : 'light'] = { roles: r, semantic: sem };
  }
  return out;
}

// ---------------------------------------------------------------- Lua emitter

const f4 = (x) => {
  const s = (Math.round(x * 10000) / 10000).toString();
  return s.includes('.') ? s : `${s}.0`;
};
const luaColor = (argb) =>
  `{ ${f4(((argb >> 16) & 255) / 255)}, ${f4(((argb >> 8) & 255) / 255)}, ${f4((argb & 255) / 255)} }`;

function emitTable(obj, indent) {
  const pad = '  '.repeat(indent);
  const lines = [];
  for (const [k, v] of Object.entries(obj)) {
    if (typeof v === 'number') lines.push(`${pad}${k} = ${luaColor(v)},`);
    else lines.push(`${pad}${k} = {\n${emitTable(v, indent + 1)}${pad}},`);
  }
  return lines.join('\n') + '\n';
}

function emitLua() {
  const keys = Object.keys(classSeeds);
  let lua = '-- GENERATED by tools/tokens/gen-tokens.mjs. Do not edit by hand.\n';
  lua += '-- @material/material-color-utilities@0.3.0, SchemeTonalSpot, contrast 0.\n';
  lua += '-- Colors are { r, g, b } in 0..1.\n\n';
  lua += 'local T = Tonic\n\n';
  lua += '---@class TonicPalettes\nT.Palettes = {\n';
  lua += `  order = { ${keys.map((k) => `"${k}"`).join(', ')} },\n`;
  lua += '  seeds = {\n';
  for (const k of keys) {
    const p = buildLua(classSeeds[k]);
    lua += `    ${k} = {\n      seed = "${p.seed}",\n`;
    for (const mode of ['dark', 'light']) {
      lua += `      ${mode} = {\n`;
      lua += `        roles = {\n${emitTable(p[mode].roles, 5)}        },\n`;
      lua += `        semantic = {\n${emitTable(p[mode].semantic, 5)}        },\n`;
      lua += '      },\n';
    }
    lua += '    },\n';
  }
  lua += '  },\n}\n';
  return lua;
}

// ---------------------------------------------------------------- Textures

// Uncompressed 32-bit TGA, white RGB with alpha from fn(x, y, size) in 0..1.
function tga(size, alphaFn) {
  const header = Buffer.alloc(18);
  header[2] = 2; // uncompressed true-color
  header.writeUInt16LE(size, 12);
  header.writeUInt16LE(size, 14);
  header[16] = 32;
  header[17] = 8 | 0x20; // 8 alpha bits, top-left origin
  const px = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4;
      px[i] = px[i + 1] = px[i + 2] = 255;
      px[i + 3] = Math.round(Math.min(1, Math.max(0, alphaFn(x, y, size))) * 255);
    }
  }
  return Buffer.concat([header, px]);
}

// Distance of the pixel center from the texture center, normalised so 1 = edge.
const dist = (x, y, size) => Math.hypot(x + 0.5 - size / 2, y + 0.5 - size / 2) / (size / 2);

// Anti-aliased white disk: the four quadrants are the shape corners.
const disk = (x, y, size) => {
  const edgePx = (1 - dist(x, y, size)) * (size / 2);
  return edgePx + 0.5;
};

// Soft falloff for pre-rendered shadows: opaque at the center, transparent at the edge.
const soft = (x, y, size) => {
  const d = Math.min(1, dist(x, y, size));
  const s = d * d * (3 - 2 * d);
  return Math.pow(1 - s, 1.6);
};

export const circleSizes = [16, 32, 64, 128];

function writeTextures() {
  const dir = resolve(ROOT, 'Tonic/Media/Textures');
  mkdirSync(dir, { recursive: true });
  for (const size of circleSizes) writeFileSync(resolve(dir, `Circle${size}.tga`), tga(size, disk));
  writeFileSync(resolve(dir, 'Shadow64.tga'), tga(64, soft));
}

// ---------------------------------------------------------------- Main

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (process.argv.includes('--json')) {
    const out = {};
    for (const [k, hex] of Object.entries(referenceSeeds)) out[k] = buildReference(hex);
    console.log(JSON.stringify(out));
  } else {
    const file = resolve(ROOT, 'Tonic/Theme/Palettes.generated.lua');
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, emitLua());
    writeTextures();
    console.log(`Wrote ${file} (${Object.keys(classSeeds).length} seeds) and textures.`);
  }
}
