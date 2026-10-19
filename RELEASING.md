# Release

## Una volta sola

1. **Font**: `pip install fonttools` e `python tools/fonts/build-fonts.py`. Genera in
   `Tonic/Media/Fonts` Roboto Serif, Roboto Flex (anche le varianti `-Tnum`), Material
   Symbols Rounded e `OFL.txt`. Controlla in gioco con `/tonic gallery` che il sottotitolo
   non segnali più i font mancanti, poi fai il commit dei `.ttf`.
2. **Progetti sugli store**: crea il progetto su CurseForge e su Wago, poi aggiungi a
   `Tonic/Tonic.toc` (e agli altri due TOC):
   ```
   ## X-Curse-Project-ID: <id CurseForge>
   ## X-Wago-ID: <id Wago>
   ```
3. **Secrets del repository** (Settings → Secrets and variables → Actions):
   - `CF_API_KEY`: token API di CurseForge
   - `WAGO_API_TOKEN`: token API di Wago
   `GITHUB_TOKEN` è automatico (GitHub Releases).
4. **Licenza**: scegli la licenza del codice e aggiungi `LICENSE`.

## A ogni release

1. In gioco: `/dump select(4, GetBuildInfo())`. Se è cambiato, aggiorna `## Interface`
   nei tre TOC.
2. `/tonic audit` su un personaggio di prova: tutte le skin devono risultare a posto.
3. `/tonic gallery`: controllo visivo, in scuro e in chiaro.
4. Aggiorna `CHANGELOG.md`.
5. Tag e push:
   ```
   git tag v1.0.0
   git push origin v1.0.0
   ```
   Il workflow `Release` rigenera palette e texture, crea il pacchetto con i tre addon
   (`Tonic`, `Tonic_Skins`, `Tonic_Config`) e lo carica sugli store configurati.
   I tag con `-beta`/`-alpha` vengono pubblicati come beta/alpha.
