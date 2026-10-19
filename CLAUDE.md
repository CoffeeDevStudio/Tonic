# Tonic — addon World of Warcraft

Restyle completo dell'interfaccia di WoW Retail (Midnight 12.x) secondo **Material Design 3**.
Il **colore dinamico** prende come seme il colore della classe del personaggio.
È un framework (core + componenti + skin engine) pensato per essere distribuito
su CurseForge e Wago, e usabile da altri addon come libreria UI.

## Nome e identificativi

| Cosa | Valore |
|---|---|
| Nome | Tonic (mai "Tonic UI": collide con la libreria React di Trend Micro) |
| Sottotitolo | Material 3 per WoW · la tua UI nei colori della tua classe |
| Tagline | EN "A tonic for your UI." · IT "Un tonico per la tua interfaccia." |
| Cartelle addon | `Tonic/` (core), `Tonic_Skins/` (LoadOnDemand), `Tonic_Config/` (LoadOnDemand) |
| Namespace globale | `Tonic` (unico globale ammesso; in ogni file `local T = Tonic`) |
| LibStub | `"Tonic-1.0"` |
| SavedVariables | `TonicDB` (account), `TonicCharDB` (personaggio) |
| Slash | `/tonic` |
| GitHub | organizzazione `tonic-wow` (o `tonicaddon`) |

## Struttura del repository

```
Tonic/
  Tonic.toc
  Libs/                  LibStub (fase 1); poi CallbackHandler, LibSharedMedia, LibSerialize, LibDeflate
  Core/                  Init, Pool, Modules (lifecycle), Events (bus), Combat (coda lockdown), DB (profili + migrazioni), Scale (dp → pixel-perfect), Slash
  Locales/               traduzioni (le chiavi sono le stringhe inglesi)
  Theme/                 Palettes.generated.lua (GENERATO), Scheme, Typography, Shape, Elevation, Motion, ThemeManager
  Primitives/            Surface, StateLayer, Ripple, Text, Icon
  Components/            Button, IconButton, FAB, Card, Switch, Checkbox, Radio, Slider, TextField, Menu, Dialog, Snackbar, Tabs, Tooltip, List
  Skin/                  SkinEngine (registry + ADDON_LOADED), Helpers (StripTextures, SkinButton…)
  Gallery/               /tonic gallery (QA visiva)
  Media/                 Fonts (Roboto Serif, Roboto Flex statici, Material Symbols Rounded), Textures (.tga GENERATE: Circle16..128, Shadow64)
Tonic_Skins/             uno skin per area Blizzard
Tonic_Config/            opzioni dichiarative renderizzate con i componenti Tonic (dogfooding)
tools/tokens/            pipeline Node che genera Palettes.generated.lua e le texture (npm run gen / npm test)
spec/                    test busted (stub WoW in spec/helpers/wow.lua)
test/                    tonic-tokens.json di riferimento
```

Il core è una dipendenza standalone (`## Dependencies: Tonic`) e non va embeddato:
deve esistere un solo ThemeManager e i path dei media sono fissi.

## Vincoli di piattaforma (non negoziabili)

- **Taint**: sui frame Blizzard solo `hooksecurefunc` e `HookScript`. Mai riassegnare funzioni Blizzard e mai usare `SetScript` sui loro frame.
- **Combat lockdown**: posizionamento e visibilità dei frame protetti passano da `T.Combat:Defer(fn)`, che svuota la coda a `PLAYER_REGEN_ENABLED`.
- **Secret values (Midnight)**: lo skin layer non legge né confronta dati di combattimento. Li inoltra soltanto alle API lato C (`StatusBar:SetValue`, `SetText`, `SetVertexColor`, color curve, `SecondsFormatter`).
- **Niente blur o box-shadow**: shape = texture 9-slice bianche tintate con `SetVertexColor`; ombre = texture 9-slice pre-renderizzate; ripple = AnimationGroup + MaskTexture con la stessa shape.
- **Font**: un file per peso. Fallback per alfabeto con `CreateFontFamily` (koKR, zhCN, zhTW). I ruoli tipografici sono `Font` object condivisi.
- **Ogni skin è isolato**: gira in `xpcall(fn, geterrorhandler())` e ha un toggle in config. Il comando `/tonic audit` verifica che i frame attesi esistano dopo ogni patch.
- **Performance**: niente `OnUpdate` per widget (un solo ticker condiviso per i tween); pool obbligatori per i frame dinamici; liste su `ScrollBox` + `DataProvider` di Blizzard.
- **Interface nel TOC**: usa il numero della patch live corrente, che si ottiene con `/dump select(4, GetBuildInfo())`.
- **Globali**: oltre a `Tonic` esistono solo quelli imposti da WoW: SavedVariables, `SLASH_TONIC1`, `LibStub` e i nomi `TonicFont_*` dei Font object (richiesti da `CreateFontFamily`).

## Pipeline dei token

- La sorgente è `tools/tokens/` (Node). Lo script di partenza è `gen-tokens.mjs`, con `@material/material-color-utilities@0.3.0`.
- **Schema**: `SchemeTonalSpot`, contrasto 0, dark e light.
- **Semi** (colore di classe, chiave = classFile): Mago `#3FC7EB`, Paladino `#F48CBA`, Druido `#FF7C0A`, Cavaliere della Morte `#C41E3A`, Evocatore `#33937F`, Stregone `#8788EE`, Guerriero `#C69B6D`, Cacciatore `#AAD372`, Ladro `#FFF468`, Sacerdote `#FFFFFF`, Sciamano `#0070DD`, Monaco `#00FF98`, Cacciatore di Demoni `#A330C9`. `DEFAULT` `#6750A4` se la classe non è nota.
- **Colori semantici** (salute, mana, ira, energia, ostile, canali chat, qualità degli oggetti): `Blend.harmonize` verso il seme, poi palette tonale con chroma ≥ 48.
  - Dark: color = tono 80, barra = tono 70, container = tono 30, onContainer = tono 90.
  - Light: color = tono 40, barra = tono 50, container = tono 90, onContainer = tono 10.
- **Uscita**: `Tonic/Theme/Palettes.generated.lua`. Non si modifica mai a mano; la CI la rigenera prima del packaging.
- **Riferimento**: `test/tonic-tokens.json` contiene l'output attuale per i sei semi; `npm test` verifica che la pipeline lo riproduca. In Lua la qualità comune usa la palette neutra (decisione di design), quindi diverge dal JSON solo lì.

## Decisioni di design (dai mockup)

- **Modalità e superfici**
  - Scuro di default, chiaro opzionale.
  - Pannelli HUD semitrasparenti, opacità predefinita 0,88 e regolabile da 0,60 a 1,00.
  - Elevazione tonale: lowest = caricamento, low = finestre, container = pannelli HUD, high = menu/tooltip/barra azioni, highest = slot/campi/tracce.
  - Ombre solo su finestre e menu; i pannelli HUD restano piatti.
- **Forma**: XS 4 (snackbar), S 8 (aure, chip), M 12–14 (slot, menu, tooltip ricchi), L 16 (pannelli HUD), XL 28 (finestre, minimappa), Full (barre, pulsanti, toolbar).
- **Tipografia**
  - Roboto Serif per Display e Headline (titoli di finestra, livello oggetti).
  - Roboto Flex per Title, Body e Label.
  - Cifre tabulari nei valori.
- **Stati M3**
  - Hover 8%, focus/premuto 10%, disabilitato: contenitore onSurface 12% e contenuto 38%.
  - Ripple al premuto, disattivabile.
- **Stati di gioco**
  - Ricarica: oscuramento radiale con numero.
  - Proc: anello tonale tertiary.
  - Fuori portata: tinta error.
  - Non utilizzabile: 38%.
  - Magia dissipabile: badge tertiaryContainer.
- **Qualità oggetti**: contenitore tonale più nome nel tono 80. Comune neutro, senza tinta. Solo il leggendario ha anche l'anello.
- **Decisione aperta**: con semi caldi la salute armonizzata vira al giallo-verde (`#83BC09`). Valutare se escludere la salute dall'armonizzazione per leggibilità.

## Brand

- Logo: fiala di tonico con liquido a 4 bande tonali (primary toni 90/80/60/40), tappo tertiary 80, contorno e collo primary 90.
- Il logo cambia colore con la classe.
- Varianti dell'icona: 400 px (CurseForge/Wago), 64 px (`## IconTexture` nel TOC), 32 px (due bande, minimappa), 16 px (solo sagoma).
- Wordmark: "Tonic" in Roboto Serif SemiBold, tracking leggermente negativo.

## Convenzioni di codice

- Annotazioni LuaLS (`---@class`, `---@param`) e definizioni WoW API di Ketho.
- luacheck con i globali WoW; busted per il codice puro (risoluzione token, migrazioni, merge dei defaults) con stub di `CreateFrame`.
- Componenti basati su mixin (`CreateFromMixins`) con il contratto `:ApplyTheme(theme)`, `:SetState(state)`, `:Update(props)`, `:Release()`.
- Packaging con BigWigs packager in GitHub Actions verso CurseForge, Wago e GitHub Releases. Le librerie esterne stanno in `.pkgmeta`.
- In gioco `/tonic gallery` mostra tutti i componenti in tutti gli stati, in scuro e chiaro, per la QA visiva a ogni patch.

## Roadmap

1. Core, pipeline dei token, primitive Surface/Text e gallery.
2. Button, IconButton, Switch, Checkbox, Slider, TextField e `Tonic_Config` in dogfooding.
3. Skin engine sulle schermate fuori combattimento: Character, Borse, Game Menu, Collections.
4. Tooltip, menu, chat.
5. Per ultimi unit frame e nameplate: solo pass-through dei secret values.
