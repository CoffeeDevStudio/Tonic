# Font Tonic

Tonic cerca questi file in questa cartella (un file per peso). Se un file manca usa i font Blizzard e la gallery lo segnala.

| File | Uso |
|---|---|
| `RobotoSerif-Regular.ttf` | Display, Headline |
| `RobotoSerif-SemiBold.ttf` | wordmark |
| `RobotoFlex-Regular.ttf` | Title Large, Body |
| `RobotoFlex-Medium.ttf` | Title Medium/Small, Label |
| `RobotoFlex-Regular-Tnum.ttf` | valori con cifre tabulari |
| `RobotoFlex-Medium-Tnum.ttf` | valori con cifre tabulari |

Roboto Flex è distribuito come font variabile, quindi le istanze statiche vanno generate (per esempio con `fonttools varLib.instancer`).
Le varianti `-Tnum` hanno la feature `tnum` congelata nel file, perché WoW non attiva le feature OpenType.
Licenza: SIL Open Font License 1.1 (va inclusa insieme ai file).
