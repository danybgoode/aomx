# Public landing page

`index.html` is the responsive promotional page for Battle for La Roma, based on the approved `battle-for-la-roma-landing-lore-v3.html` reference. It uses local image assets extracted from that supplied concept file and has no build step or external runtime dependencies.

Preview from the repository root with `python3 -m http.server 8765 --directory landing` and open `http://127.0.0.1:8765/`. Keep `index.html` and `assets/` together when publishing.

The hero and final section link to the unified public [itch.io page](https://danybgoode.itch.io/battle-for-la-roma-play) for Web play and to its macOS download section. Both builds include five solo maps, Campaign, Wonder, solo 2 v 2 and player-created private rooms. The four age panels use screenshots from the actual Godot game.

The public site is deployed to Cloudflare Pages at <https://battle-for-la-roma.pages.dev/>. It is a Direct Upload project with production branch `master`. Publish the `landing/` directory with `wrangler pages deploy landing --project-name battle-for-la-roma --branch master` using `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` in the operator environment. Check the canonical URL and image assets after each upload. Do not publish `.env.local` or the root prototype HTML files.
