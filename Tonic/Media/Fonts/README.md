# Font Tonic

I file si generano con `python tools/fonts/build-fonts.py` (richiede `pip install fonttools`).
Se un file manca, Tonic usa i font Blizzard e la gallery lo segnala.

| File | Uso |
|---|---|
| `RobotoSerif-Regular.ttf` | Display, Headline |
| `RobotoSerif-SemiBold.ttf` | wordmark |
| `RobotoFlex-Regular.ttf` | Title Large, Body |
| `RobotoFlex-Medium.ttf` | Title Medium/Small, Label |
| `RobotoFlex-Regular-Tnum.ttf`, `RobotoFlex-Medium-Tnum.ttf` | valori con cifre tabulari |
| `MaterialSymbolsRounded.ttf` | icone (sottoinsieme dei codepoint usati) |
| `OFL.txt` | licenza SIL Open Font License 1.1 |

WoW non gestisce assi variabili né feature OpenType: lo script crea istanze statiche e
"congela" la feature `tnum` nelle varianti `-Tnum`. Senza Material Symbols le icone
principali usano le texture generate in `Media/Textures/Icons`.
