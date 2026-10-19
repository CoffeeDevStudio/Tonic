// Tonic token pipeline.
// Generates Tonic/Theme/Palettes.generated.lua and the shape/shadow textures in Tonic/Media/Textures.
// Usage: node gen-tokens.mjs            (writes the outputs)
//        node gen-tokens.mjs --json     (prints the reference-format JSON for the six reference seeds)
import {
  argbFromHex, hexFromArgb, Hct, SchemeTonalSpot, MaterialDynamicColors as M, Blend, TonalPalette,
} from '@material/material-color-utilities';
import { writeFileSync, mkdirSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
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
    // Brand tones of the logo (vial bands, cap).
    r.tonePrimary90 = s.primaryPalette.tone(90);
    r.tonePrimary80 = s.primaryPalette.tone(80);
    r.tonePrimary60 = s.primaryPalette.tone(60);
    r.tonePrimary40 = s.primaryPalette.tone(40);
    r.toneTertiary80 = s.tertiaryPalette.tone(80);
    const sem = {};
    for (const [n, h] of Object.entries(semantic)) {
      const pal = NEUTRAL_SEMANTIC.has(n) ? s.neutralPalette : semanticPalette(h, src, HARMONIZE_EXCLUDE.has(n)).pal;
      sem[semanticLuaKeys[n]] = tones(pal, dark);
    }
    // Unharmonized health, selectable in the options (open decision on warm seeds).
    sem.healthBase = tones(semanticPalette(semantic.salute, src, true).pal, dark);
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

const clamp01 = (v) => Math.min(1, Math.max(0, v));

// Uncompressed 32-bit TGA (BGRA, top-left origin). pixelFn(x, y) -> [r, g, b, a] in 0..1.
function tgaRgba(width, height, pixelFn) {
  const header = Buffer.alloc(18);
  header[2] = 2; // uncompressed true-color
  header.writeUInt16LE(width, 12);
  header.writeUInt16LE(height, 14);
  header[16] = 32;
  header[17] = 8 | 0x20; // 8 alpha bits, top-left origin
  const px = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const [r, g, b, a] = pixelFn(x, y);
      const i = (y * width + x) * 4;
      px[i] = Math.round(clamp01(b) * 255);
      px[i + 1] = Math.round(clamp01(g) * 255);
      px[i + 2] = Math.round(clamp01(r) * 255);
      px[i + 3] = Math.round(clamp01(a) * 255);
    }
  }
  return Buffer.concat([header, px]);
}

// White TGA with alpha from alphaFn(x, y, size) in 0..1 (square) or alphaFn(x, y, w, h).
function tga(size, alphaFn, height = size) {
  return tgaRgba(size, height, (x, y) => [1, 1, 1, alphaFn(x, y, size, height)]);
}

// Minimal PNG encoder (RGBA, no interlace).
const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = CRC_TABLE[(c ^ b) & 255] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function pngChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function png(width, height, pixelFn) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    raw[y * (width * 4 + 1)] = 0;
    for (let x = 0; x < width; x++) {
      const [r, g, b, a] = pixelFn(x, y);
      const i = y * (width * 4 + 1) + 1 + x * 4;
      raw[i] = Math.round(clamp01(r) * 255);
      raw[i + 1] = Math.round(clamp01(g) * 255);
      raw[i + 2] = Math.round(clamp01(b) * 255);
      raw[i + 3] = Math.round(clamp01(a) * 255);
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; ihdr[9] = 6; // 8-bit RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    pngChunk('IHDR', ihdr), pngChunk('IDAT', deflateSync(raw, { level: 9 })), pngChunk('IEND', Buffer.alloc(0)),
  ]);
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

// Anti-aliased ring: stroke is a fraction of the outer radius. Its quadrants are outline corners.
export const ringRatios = [3, 6, 10, 15, 20, 30];
const ring = (ratio) => (x, y, size) => {
  const R = size / 2;
  const d = dist(x, y, size) * R;
  const w = R * ratio / 100;
  return Math.min(R - d + 0.5, d - (R - w) + 0.5);
};

// Pill masks for the ripple (rounded rect, radius = height / 2) at power-of-two aspects.
export const pillAspects = [2, 4, 8];
const pill = (x, y, w, h) => {
  const r = h / 2;
  const cx = Math.min(Math.max(x + 0.5, r), w - r);
  return r - Math.hypot(x + 0.5 - cx, y + 0.5 - r) + 0.5;
};

// ------------------------------------------------------------- icons (24-unit grid, stroke 2)

const segDist = (px, py, ax, ay, bx, by) => {
  const dx = bx - ax, dy = by - ay;
  const t = Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy || 1)));
  return Math.hypot(px - ax - t * dx, py - ay - t * dy);
};
// Shape primitives return a signed distance in grid units (negative inside).
const stroke = (points, closed = false, width = 2) => (px, py) => {
  let d = Infinity;
  const n = points.length;
  for (let i = 0; i < n - (closed ? 0 : 1); i++) {
    const [ax, ay] = points[i], [bx, by] = points[(i + 1) % n];
    d = Math.min(d, segDist(px, py, ax, ay, bx, by));
  }
  return d - width / 2;
};
const discShape = (cx, cy, r) => (px, py) => Math.hypot(px - cx, py - cy) - r;
const ringShape = (cx, cy, r, width = 2) => (px, py) => Math.abs(Math.hypot(px - cx, py - cy) - r) - width / 2;
const union = (...shapes) => (px, py) => Math.min(...shapes.map((s) => s(px, py)));
const subtract = (a, b) => (px, py) => Math.max(a(px, py), -b(px, py));

const rays = [];
for (let i = 0; i < 8; i++) {
  const a = (i * Math.PI) / 4;
  rays.push(stroke([[12 + Math.cos(a) * 7.5, 12 + Math.sin(a) * 7.5], [12 + Math.cos(a) * 10, 12 + Math.sin(a) * 10]]));
}

export const icons = {
  add: union(stroke([[5, 12], [19, 12]]), stroke([[12, 5], [12, 19]])),
  remove: stroke([[5, 12], [19, 12]]),
  close: union(stroke([[6, 6], [18, 18]]), stroke([[18, 6], [6, 18]])),
  check: stroke([[5, 12.5], [9.5, 17], [19, 7.5]]),
  chevron_left: stroke([[14.5, 6], [8.5, 12], [14.5, 18]]),
  chevron_right: stroke([[9.5, 6], [15.5, 12], [9.5, 18]]),
  expand_more: stroke([[6, 9.5], [12, 15.5], [18, 9.5]]),
  expand_less: stroke([[6, 14.5], [12, 8.5], [18, 14.5]]),
  arrow_back: union(stroke([[5, 12], [19, 12]]), stroke([[11, 6], [5, 12], [11, 18]])),
  menu: union(stroke([[4, 7], [20, 7]]), stroke([[4, 12], [20, 12]]), stroke([[4, 17], [20, 17]])),
  more_vert: union(discShape(12, 6, 2), discShape(12, 12, 2), discShape(12, 18, 2)),
  search: union(ringShape(10, 10, 6), stroke([[14.5, 14.5], [20, 20]])),
  light_mode: union(discShape(12, 12, 4.5), ...rays),
  dark_mode: subtract(discShape(12, 12, 8.5), discShape(16.5, 7.5, 7)),
  info: union(ringShape(12, 12, 9), stroke([[12, 11], [12, 16.5]]), discShape(12, 7.8, 1.3)),
  warning: union(stroke([[12, 3.5], [21, 19.5], [3, 19.5]], true), stroke([[12, 10], [12, 14]]), discShape(12, 16.8, 1.2)),
};

function iconTexture(shape, size = 64) {
  const unit = 24 / size;
  return tga(size, (x, y) => 0.5 - shape((x + 0.5) * unit, (y + 0.5) * unit) / unit);
}

// ------------------------------------------------------------- logo (100-unit box)

// Rounded rect with separate top/bottom radii, signed distance.
const roundedRect = (x0, y0, x1, y1, rTop, rBottom) => (px, py) => {
  const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
  const hx = (x1 - x0) / 2, hy = (y1 - y0) / 2;
  const r = py < cy ? rTop : rBottom;
  const qx = Math.abs(px - cx) - (hx - r);
  const qy = Math.abs(py - cy) - (hy - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
};

const body = roundedRect(24, 32, 76, 94, 10, 26);
const neck = roundedRect(41, 16, 59, 36, 2, 2);
const vial = union(body, neck);
const cap = roundedRect(37, 5, 63, 19, 4, 4);
const liquidArea = roundedRect(31, 39, 69, 87, 4, 19);
const LIQUID_TOP = 48;

// Layers: alpha functions in the 100-unit box.
export const logoLayers = {
  outline: (px, py) => 2.6 - Math.abs(vial(px, py)),
  cap: (px, py) => -cap(px, py),
  band1: (px, py) => Math.min(-liquidArea(px, py), py - LIQUID_TOP, LIQUID_TOP + 10 - py),
  band2: (px, py) => Math.min(-liquidArea(px, py), py - (LIQUID_TOP + 10), LIQUID_TOP + 20 - py),
  band3: (px, py) => Math.min(-liquidArea(px, py), py - (LIQUID_TOP + 20), LIQUID_TOP + 30 - py),
  band4: (px, py) => Math.min(-liquidArea(px, py), py - (LIQUID_TOP + 30)),
  // 32 px: two bands.
  bandTop: (px, py) => Math.min(-liquidArea(px, py), py - LIQUID_TOP, LIQUID_TOP + 20 - py),
  bandBottom: (px, py) => Math.min(-liquidArea(px, py), py - (LIQUID_TOP + 20)),
  // 16 px: silhouette only.
  silhouette: (px, py) => -union(vial, cap)(px, py),
};

// Coverage of a layer at a pixel, 4x4 supersampled. Distances are in box units.
function coverage(layer, x, y, size) {
  const unit = 100 / size;
  let sum = 0;
  for (let sy = 0; sy < 4; sy++) {
    for (let sx = 0; sx < 4; sx++) {
      const px = (x + (sx + 0.5) / 4) * unit;
      const py = (y + (sy + 0.5) / 4) * unit;
      sum += layer(px, py) > 0 ? 1 : 0;
    }
  }
  return sum / 16;
}

const hexRgb = (argb) => [((argb >> 16) & 255) / 255, ((argb >> 8) & 255) / 255, (argb & 255) / 255];

// Composites the colored logo for a seed (dark scheme tones).
function logoPixel(seedHex, size, variant) {
  const s = new SchemeTonalSpot(Hct.fromInt(argbFromHex(seedHex)), true, CONTRAST);
  const p = (t) => hexRgb(s.primaryPalette.tone(t));
  const stack = variant === 16
    ? [['silhouette', p(80)]]
    : variant === 32
      ? [['bandTop', p(80)], ['bandBottom', p(40)], ['outline', p(90)], ['cap', hexRgb(s.tertiaryPalette.tone(80))]]
      : [['band1', p(90)], ['band2', p(80)], ['band3', p(60)], ['band4', p(40)], ['outline', p(90)],
        ['cap', hexRgb(s.tertiaryPalette.tone(80))]];
  return (x, y) => {
    let r = 0, g = 0, b = 0, a = 0;
    for (const [layer, color] of stack) {
      const c = coverage(logoLayers[layer], x, y, size);
      // "over" compositing, premultiplied.
      r = color[0] * c + r * (1 - c); g = color[1] * c + g * (1 - c); b = color[2] * c + b * (1 - c);
      a = c + a * (1 - c);
    }
    return a > 0 ? [r / a, g / a, b / a, a] : [0, 0, 0, 0];
  };
}

const BRAND_SEED = classSeeds.MAGE;

function writeTextures() {
  const dir = resolve(ROOT, 'Tonic/Media/Textures');
  mkdirSync(dir, { recursive: true });
  for (const size of circleSizes) writeFileSync(resolve(dir, `Circle${size}.tga`), tga(size, disk));
  writeFileSync(resolve(dir, 'Shadow64.tga'), tga(64, soft));
  for (const ratio of ringRatios) writeFileSync(resolve(dir, `Ring${ratio}.tga`), tga(128, ring(ratio)));
  for (const aspect of pillAspects) {
    writeFileSync(resolve(dir, `Pill${aspect}.tga`), tga(64 * aspect, (x, y, w, h) => pill(x, y, w, h), 64));
  }

  const iconDir = resolve(dir, 'Icons');
  mkdirSync(iconDir, { recursive: true });
  for (const [name, shape] of Object.entries(icons)) writeFileSync(resolve(iconDir, `${name}.tga`), iconTexture(shape));

  // White logo layers, tinted at runtime with the class tones.
  const logoDir = resolve(dir, 'Logo');
  mkdirSync(logoDir, { recursive: true });
  for (const name of ['outline', 'cap', 'band1', 'band2', 'band3', 'band4']) {
    writeFileSync(resolve(logoDir, `${name}64.tga`), tga(64, (x, y) => coverage(logoLayers[name], x, y, 64)));
  }
  for (const name of ['outline', 'cap', 'bandTop', 'bandBottom']) {
    writeFileSync(resolve(logoDir, `${name}32.tga`), tga(32, (x, y) => coverage(logoLayers[name], x, y, 32)));
  }
  writeFileSync(resolve(logoDir, 'silhouette16.tga'), tga(16, (x, y) => coverage(logoLayers.silhouette, x, y, 16)));

  // Static colored icons: TOC IconTexture (64) and store pages (400, plus 32/16 previews).
  writeFileSync(resolve(dir, 'Icon64.tga'), tgaRgba(64, 64, logoPixel(BRAND_SEED, 64, 64)));
  const brandDir = resolve(ROOT, 'brand');
  mkdirSync(brandDir, { recursive: true });
  writeFileSync(resolve(brandDir, 'icon-400.png'), png(400, 400, logoPixel(BRAND_SEED, 400, 400)));
  writeFileSync(resolve(brandDir, 'icon-64.png'), png(64, 64, logoPixel(BRAND_SEED, 64, 64)));
  writeFileSync(resolve(brandDir, 'icon-32.png'), png(32, 32, logoPixel(BRAND_SEED, 32, 32)));
  writeFileSync(resolve(brandDir, 'icon-16.png'), png(16, 16, logoPixel(BRAND_SEED, 16, 16)));
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
