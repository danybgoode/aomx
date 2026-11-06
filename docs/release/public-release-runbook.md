# Public release runbook · Web and macOS

This is how a merged change reaches players on the [public itch.io page](https://danybgoode.itch.io/battle-for-la-roma-play). It consolidates the steps used for the [unified release](../public-consolidation-release-2026-11-05.md) and the [in-match release](../interface-review/in-match-public-release-2026-11-05.md), plus the gaps found reviewing them on 2026-11-05. Each release adds its own dated record; this file holds the procedure.

| Platform | itch.io channel | Package |
|---|---|---|
| Web (HTML5) | `danybgoode/battle-for-la-roma-play:html5-public` | `battle-for-la-roma-public-<sha>-web.zip` |
| macOS | `danybgoode/battle-for-la-roma-play:mac-public` | `battle-for-la-roma-public-<sha>-macos.zip` (ad-hoc signed) |

**Public match origin:** `https://alpha-api.159.54.158.4.sslip.io`, which is the value of `AOMX_PUBLIC_MATCH_URL`. The host allows the Web origin `https://html-classic.itch.zone`. On Apple Silicon, install butler from the `darwin-arm64` channel (`https://broth.itch.zone/butler/darwin-arm64/LATEST/archive/default`); the `darwin-amd64` build needs Rosetta.

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

```sh
npm run public:verify -- --before-upload
```

This checks that both ZIPs match the manifest and the manifest came from a clean tree. It runs the local macOS app's codesign and a bounded headless start, and confirms the match host is healthy, allows the itch Web origin (204) and rejects others (403). The report is written to `dist/public/<build>-verify-before-upload.json`.

By hand: unzip and serve the Web package (`python3 -m http.server`), open it in a browser, start a quick match, and switch the language under Settings.

## 4 · Publish

```sh
V=public-<sha>
butler push dist/public/battle-for-la-roma-$V-web.zip   danybgoode/battle-for-la-roma-play:html5-public --userversion $V
butler push dist/public/battle-for-la-roma-$V-macos.zip danybgoode/battle-for-la-roma-play:mac-public  --userversion $V
butler status danybgoode/battle-for-la-roma-play
```

Wait until both channels show the new version as processed.

## 5 · Verify what players get

```sh
npm run public:verify
```

Don't rely on the upload having succeeded; this checks what players actually download. It checks that both channels report the build as processed at the right version. It then fetches each channel into an empty folder and compares every file with the local package (SHA-256). The downloaded macOS app gets a codesign and headless start check, the host is checked again, and the itch page and both landing pages must return 200. It exits 1 if anything fails. Attach `dist/public/<build>-verify-after-upload.json` to the release record. Use `--build public-<sha>` to check a release other than HEAD.

By hand: open the itch-served Web build in a browser and start a match. The script proves its files are identical to the package you tested in step 3, but it doesn't play it.

## 6 · Record and sync

- Add a dated release record next to the feature's docs. Include the commit, both butler build numbers, ZIP hashes, which checks ran, the host image if it changed, and what was **not** verified (for example a physical phone or a full downloaded match).
- Update the epic's Definition of Done and run the [roadmap sync](../../Roadmap/WAYS-OF-WORKING.md#golden-frijoles-roadmap-sync).

## Rollback

Keep the previous release's ZIPs in `dist/public/`. Push them back to both channels with their original `--userversion`. If the host image changed, roll it back too with `deploy/alpha/deploy.sh <previous-sha>`.

## Known gaps (2026-11-05 review)

- **macOS builds are ad-hoc signed and not notarized** (`codesign/codesign=1`, `notarization=0`). Players who download the ZIP in a browser get Gatekeeper's "cannot verify the developer" prompt and must right-click → Open. The itch app does not quarantine downloads. Fixing this needs an Apple Developer ID and notarization in the export.
- **The macOS bundle version never changes** (`0.1.0`, build `1`), so Finder and crash reports can't tell releases apart. Set it from the build ID at export.
- Before 2026-11-05 the export accepted a dirty working tree under a clean commit ID, did not check that translations shipped, and checks after the upload were manual. All three are now scripted.
