# Bilingual game public release · 2026-11-05

The game localization from [PR #117](https://github.com/danybgoode/aomx/pull/117) merged as `36868ff112ac`. Both public builds were exported from that exact commit with a clean tree (`source_clean: true`), following the [public release runbook](public-release-runbook.md). Locales: es-MX and English.

| Public channel | Butler build | ZIP SHA-256 | Version |
| --- | --- | --- | --- |
| `danybgoode/battle-for-la-roma-play:html5-public` | `#2310032` (from `#2309749`) | `357ebf301f779c7e79e1557a922a3646acfebd4125ab95c56361aa0c666700dd` | `public-36868ff112ac` |
| `danybgoode/battle-for-la-roma-play:mac-public` | `#2310033` (from `#2309750`) | `8c100640ce861411cd338cb1e4f6b26e69d9be53d775fc2f17548cc58479dc9b` | `public-36868ff112ac` |

Game version `godot-4.7.2-skirmish-12`, content `la-roma-world-6`, simulation hash `12ec58f2adf71cd7eaddfa91bfb3191d9678899d1484caa4b5ae5b1b52979034`. The manifest is `dist/public/public-36868ff112ac.json` (ignored local artifact).

## Match host

No host change was needed. The simulation hash equals the one compiled into the previous live build (`public-e60fb1c61a4e`); `skirmish.gd`, `rules_content.gd` and `skirmish.v1.json` were untouched. Before upload, `https://alpha-api.159.54.158.4.sslip.io/healthz` returned `{"ok":true}` (200). A preflight to `/v1/match/create` returned 204 for `https://html-classic.itch.zone` and 403 for a foreign origin.

## Checks

- Export smoke passed: campaign, Wonder, five maps, 2 v 2 and public rooms. Spanish and English translations loaded, and both catalogs were present inside the Web and macOS packages.
- Local macOS package: `codesign --verify --deep --strict` passed, and a bounded headless start exited 0.
- Local Web package in headless Chrome: Godot 4.7.2 booted with no page errors. A Spanish-locale browser opened in Spanish (with the Idioma picker shown) and an English-locale browser in English.
- After processing, `butler fetch` of both channels matched every file of the local packages (9 files each).
- Fetched macOS app: strict codesign verification passed, and a bounded headless start exited 0.
- The anonymous [game page](https://danybgoode.itch.io/battle-for-la-roma-play) and the [landing page](https://battle-for-la-roma.pages.dev/) returned 200.
- Before export: Godot headless suite 42/42 including `localization_test.gd`; `npm test` 58 pass, 3 skipped, 0 fail; PR #117 CI (`verify`, CodeQL) green.

## Not verified

- A full match from the downloaded builds, played by a person.
- A human-played two-person online room on the new build (the host preflight and version match were checked).
- A physical phone, and Spanish layouts at touch and portrait sizes.
- An owner read-through of the Spanish copy in play.
- The itch-served Web page itself in a browser session. Its files were proven identical to the package tested locally.

Public builds send no play events, so no completion baseline by language is claimed.
