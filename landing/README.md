# Public landing page

The promotional page for Battle for La Roma ships in Spanish (`/`, es-MX) and English (`/en/`) from one template. All copy follows the [voice and style guide](../docs/brand/voice.md); the [2026-11-05 review](../docs/brand/landing-review-2026-11-05.md) explains the structure.

## Layout

| Path | What it holds |
|---|---|
| `src/index.html` | Markup, styles and scripts, with `{{key}}` placeholders. There is no copy here. |
| `i18n/es-MX.json`, `i18n/en.json` | Every visible string, plus meta tags and alt text. Both files must carry the same keys. |
| `assets/` | WebP images, the OG share image, the favicon and the self-hosted Anton font (SIL OFL, `assets/fonts/OFL.txt`) |
| `static/` | Files copied to the site root as-is (Cloudflare `_headers`) |
| `../scripts/build-landing.mjs` | Zero-dependency build that writes `dist/landing/` |

Template tags: `{{path.to.key}}`, `{{#each list}}…{{@field}}…{{/each}}` (`{{@}}` for string lists, `{{@index}}` for the position), and `{{json:path}}` for data the page script reads.

## Editing copy

1. Change the string in **both** locale files. English is written fresh, not translated: jokes may differ, but facts and claims must match.
2. Run `npm run landing:check`. It fails on missing or extra keys and on HTML inside attribute values, and it warns when the two languages differ in length by more than 40% (a sign a card may overflow).
3. Run `npm run landing:build`, then preview with `python3 -m http.server 8790 --directory dist/landing` and open `http://127.0.0.1:8790/` and `/en/`.

`tests/landing.test.mjs` runs inside `npm test`. It renders both pages and enforces the guide's Spanish spelling rules (*solo*, *coctel*, « » quotes).

## Language behavior

Each language has its own crawlable URL with `hreflang` alternates; `/` is canonical Spanish, so existing links keep working. Nothing redirects automatically. A small notice appears only when the browser language doesn't match the page and the visitor hasn't chosen yet. The ES | EN switch keeps the current section anchor and stores the choice in `localStorage` (`bflr-lang`).

## Publishing

The site is a Cloudflare Pages Direct Upload project (`battle-for-la-roma`, production branch `master`) at <https://battle-for-la-roma.pages.dev/>. Build first, then deploy the build output:

```sh
npm run landing:build
wrangler pages deploy dist/landing --project-name battle-for-la-roma --branch master
```

Use `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` from the operator environment. Locally, the ignored `.env.local` stores them as `ACCOUNT_ID` and `API_TOKEN`, so map them when deploying: `set -a; . ./.env.local; set +a; CLOUDFLARE_ACCOUNT_ID="$ACCOUNT_ID" CLOUDFLARE_API_TOKEN="$API_TOKEN" npx wrangler pages deploy …`. Pass `--commit-hash "$(git rev-parse HEAD)"` so the deployment records its source. After each upload, check `/`, `/en/` and a few image assets. Do not publish `.env.local` or the root prototype HTML files.

The CTAs link to the unified public [itch.io page](https://danybgoode.itch.io/battle-for-la-roma-play) for Web play and its macOS download section. The age cards and the gameplay figure use real Godot captures; the hero, faction portraits, city map and closing poster are concept art, and the footer says so once.
