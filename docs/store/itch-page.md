# itch.io page strategy · Battle for La Roma

Page: <https://danybgoode.itch.io/battle-for-la-roma-play>. butler only uploads builds; the page itself (copy, cover, screenshots, banner, tags, theme) is edited in the itch dashboard. Assets live in `docs/store/itch/`, and the description is `docs/store/itch/description.html`.

## Goal and audience

**Goal:** turn a visitor into someone who plays one match in the browser and leaves a comment. A store sale isn't the goal: the game is free and in development, and what we need is feedback.

**Who lands here:** first, Mexican and other Spanish-speaking players who know classic RTS games (from the landing page, friends and Mexican gaming communities). Second, English-speaking strategy players browsing itch.

**What they need in five seconds:** it's an RTS, it's free, it runs in the browser right now, and it's funny about Mexico City without being mean.

## Principles

1. **Play button first.** Everything above the fold points at *Run game*. Nothing makes them read before playing.
2. **Real game in the screenshots, concept art in the dressing.** All five screenshots are unedited captures from the current Spanish build; the cover, banner and description art are concept art, and the page says so.
3. **Lead with fun, end with honesty.** Caveats (local saves, phones, the macOS Gatekeeper prompt, room limits) move from the opening paragraph to a short FAQ at the bottom.
4. **Ask for specific feedback.** Three easy questions beat "let us know what you think".
5. **Spanish first, English right below.** The same structure in both, with the English rewritten for English speakers rather than translated, per the [voice guide](../brand/voice.md).

## Page structure

| Order | Element | Asset / text |
|---|---|---|
| Header | Banner (custom header image) | `banner-960.png`: logo plus all four faction banners |
| Above the fold | Web embed, *Run game* | Viewport 1280×800, fullscreen button on, click to launch |
| Sidebar | Five screenshots, in order | `screenshot-1-home` … `screenshot-5-large` |
| Description | Hook → what's in → how it plays → factions → coming next → **help us test** → FAQ → English | `description.html` with `resources-960`, `factions-960`, `units-960`, `landmarks-960` |
| Browse grid | Cover image (630×500) | `cover-630x500.png` |

## Settings

- **Title:** Battle for La Roma
- **Short description:** Un RTS clásico por la Ciudad de México · Gratis en navegador y macOS · ES / EN
- **Classification:** Game · **Release status:** In development · **Genre:** Strategy
- **Tags (10):** real-time-strategy, rts, strategy, base-building, isometric, pixel-art, mexico, satire, multiplayer, spanish
- **Pricing:** No payments (free)
- **Community:** Comments **on**, because the description asks for feedback there
- **Theme:** keep the current colors, which match the landing page (background `#0d1820`, text `#fff1d1`, links and buttons `#54dfcf`). Add the banner.
- **AI disclosure:** keep the existing disclosure

## Measuring it

itch analytics (views → plays → comments) is the only signal, since public builds send no play events. Compare the week after the change with the week before, and read every comment, tagging it *onboarding*, *bug*, *balance* or *copy*.
