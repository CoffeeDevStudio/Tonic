# Tonic

**Material 3 for WoW · your UI in your class colors**
*A tonic for your UI.*

Tonic restyles the World of Warcraft (Retail, Midnight 12.x) interface following
Material Design 3. Dynamic color takes your class color as its seed: a Mage gets a
cool cyan scheme, a Druid a warm orange one, in dark (default) or light mode.

## Features

- **Dynamic color** from the class color (Material Color Utilities, Tonal Spot),
  dark and light, with harmonized semantic colors for health, power, chat and item quality.
- **Skins** for character, bags, game menu, collections, tooltips, menus, chat,
  unit frames and nameplates. Each skin is isolated and can be turned off.
- **Material 3 components**: buttons, icon buttons, FAB, cards, switches, checkboxes,
  radios, sliders, text fields, menus, dialogs, snackbars, tabs, tooltips, lists.
- **Options built with Tonic itself** (`/tonic`), profiles per character.
- **Gallery** (`/tonic gallery`): every token and component in every state.
- **Audit** (`/tonic audit`): checks the skins against the current patch.
- Safe by design: no taint (hooks only), combat lockdown aware, and Midnight's secret
  values are never read, only forwarded to Blizzard's own widgets.

## Commands

| Command | |
|---|---|
| `/tonic` | options |
| `/tonic gallery` | component gallery |
| `/tonic audit` | skin check |
| `/tonic mode dark\|light\|toggle` | color mode |
| `/tonic seed <CLASS>\|auto` | seed color |
| `/tonic opacity 0.60-1.00` | HUD panel opacity |

## For addon authors

Tonic is also a UI library. Add `## Dependencies: Tonic` and use it through LibStub:

```lua
local T = LibStub("Tonic-1.0")
local button = T.Button:Acquire(parent, { text = "Save", variant = "filled", onClick = save })
T.Snackbar:Show("Saved")
```

Every component follows the same contract: `:ApplyTheme(theme)`, `:SetState(state)`,
`:Update(props)`, `:Release()`. Colors come from `T.Theme:GetTheme():RGB("primary")`.

---

## Italiano

**Material 3 per WoW · la tua UI nei colori della tua classe.** *Un tonico per la tua interfaccia.*

Tonic ridisegna l'interfaccia di World of Warcraft secondo Material Design 3, con il
colore dinamico che prende come seme il colore della tua classe. Skin per le finestre
Blizzard, componenti M3, opzioni costruite con Tonic stesso (`/tonic`), gallery
(`/tonic gallery`) e audit delle skin a ogni patch (`/tonic audit`).

## Development

```
tools/tokens   npm test (reference tokens) · npm run gen (palettes + textures)
tools/fonts    python build-fonts.py (static fonts, needs fonttools)
spec/          busted (WoW API stubs in spec/helpers/wow.lua)
```

See `CLAUDE.md` for the architecture and constraints, `RELEASING.md` for releases.
