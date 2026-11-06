# Public release runbook · Web and macOS

This is how a merged change reaches players on the [public itch.io page](https://danybgoode.itch.io/battle-for-la-roma-play). It consolidates the steps used for the [unified release](../public-consolidation-release-2026-11-05.md) and the [in-match release](../interface-review/in-match-public-release-2026-11-05.md), plus the gaps found reviewing them on 2026-11-05. Each release adds its own dated record; this file holds the procedure.

| Platform | itch.io channel | Package |
|---|---|---|
| Web (HTML5) | `danybgoode/battle-for-la-roma-play:html5-public` | `battle-for-la-roma-public-<sha>-web.zip` |
| macOS | `danybgoode/battle-for-la-roma-play:mac-public` | `battle-for-la-roma-public-<sha>-macos.zip` (ad-hoc signed) |

## 1 · Before exporting

1. The change is merged to `master` through a PR, and **Project checks** (`verify`) and **CodeQL** passed on the merge commit.
2. Check out exactly that commit. The export refuses uncommitted or untracked files under `game/` or `src/`, because the build ID names the commit.
3. **Decide whether the match host must change first.** Online rooms admit a client only when its `game_version`, `content_version`, schema versions, `simulation_hash` and `content_hash` match the host (`src/multiplayer/versions.mjs`). The simulation hash covers `game/skirmish.gd` and `game/rules_content.gd`; the content hash covers `game/content/skirmish.v1.json`. Run `git diff <live-commit> -- game/skirmish.gd game/rules_content.gd game/content/skirmish.v1.json src/multiplayer/versions.mjs`:
   - **Empty:** the live host stays compatible. Publish only the clients.
   - **Not empty:** deploy the CI-built `ghcr.io/danybgoode/aomx-match:<sha>` image first (`deploy/alpha/deploy.sh`, with backup and restore checks per [deploy/alpha/README.md](../../deploy/alpha/README.md)), verify `/healthz`, the itch Web origin preflight (204) and a foreign origin (403), then publish the clients. If clients ship first, players' room joins fail until the host catches up.
4. Tools: Godot 4.7.2 with export templates (`GODOT_BIN`), `butler` logged in to the itch account (`butler login`), and the public match origin (`AOMX_PUBLIC_MATCH_URL`).

## 2 · Export

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot \
AOMX_PUBLIC_MATCH_URL=<public match origin> \
npm run public:export
```

This writes both ZIPs and `public-<sha>.json` (commit, versions, locales, simulation hash, SHA-256 of each ZIP) to `dist/public/`. It fails unless:
- the setup smoke passes (campaign, Wonder, five maps, 2 v 2, public rooms),
- Spanish and English translations load, and
- both packages contain the translation catalogs.

## 3 · Check the packages locally

- macOS: unzip into an empty folder, then run `codesign --verify --deep --strict` on the `.app` and a bounded headless start of its binary.
- Web: unzip and serve the folder (`python3 -m http.server`), open it in a browser, start a quick match, and switch the language under Settings.
- Look at the home screen once in each language (`AOMX_LOCALE=es` / `en`).

## 4 · Publish

```sh
V=public-<sha>
butler push dist/public/battle-for-la-roma-$V-web.zip   danybgoode/battle-for-la-roma-play:html5-public --userversion $V
butler push dist/public/battle-for-la-roma-$V-macos.zip danybgoode/battle-for-la-roma-play:mac-public  --userversion $V
butler status danybgoode/battle-for-la-roma-play
```

Wait until both channels show the new version as processed.

## 5 · Verify what players get

1. `butler fetch` each channel into an empty folder and compare every file with the local package (SHA-256). Do not rely on the upload having succeeded.
2. Fetched macOS app: `codesign --verify --deep --strict` and a bounded headless start.
3. The anonymous game page returns HTTP 200, and the Web build opens a match in a fresh headless Chrome session.
4. If the host changed: health 200, origin preflight 204, foreign origin 403.
5. The landing page play links still land on the game.

## 6 · Record and sync

- Add a dated release record next to the feature's docs. Include the commit, both butler build numbers, ZIP hashes, which checks ran, the host image if it changed, and what was **not** verified (for example a physical phone or a full downloaded match).
- Update the epic's Definition of Done and run the [roadmap sync](../../Roadmap/WAYS-OF-WORKING.md#golden-frijoles-roadmap-sync).

## Rollback

Keep the previous release's ZIPs in `dist/public/`. Push them back to both channels with their original `--userversion`. If the host image changed, roll it back too with `deploy/alpha/deploy.sh <previous-sha>`.

## Known gaps (2026-11-05 review)

- **The public match origin is not recorded in the repo.** The value every export needs lives only in operator environments and in the built Web package. Record it here once confirmed.
- **macOS builds are ad-hoc signed and not notarized** (`codesign/codesign=1`, `notarization=0`). Players who download the ZIP in a browser get Gatekeeper's "cannot verify the developer" prompt and must right-click → Open. The itch app does not quarantine downloads. Fixing this needs an Apple Developer ID and notarization in the export.
- **The macOS bundle version never changes** (`0.1.0`, build `1`), so Finder and crash reports can't tell releases apart. Set it from the build ID at export.
- **Steps 3 and 5 are manual.** A script that fetches both channels, compares hashes and runs the codesign and start checks would make every release verifiable the same way.
- Before 2026-11-05 the export accepted a dirty working tree under a clean commit ID, and did not check that translations shipped. Both are now enforced.
