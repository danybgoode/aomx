# Landing page review — 2026-11-05

Scope: `landing/index.html` as live at <https://battle-for-la-roma.pages.dev/>, which is byte-identical to `master` at `b7f45dc`. Voice reference: [voice.md](voice.md). The page was reviewed in rendered Chromium (1440 px and 390 px), WebKit (iPhone 14 profile) and from source.

## 1. Diagnosis

The page has strong raw material: the four ages arc, the ticker, the FAQ eyebrow ("Preguntas que haría tu tía en el grupo") and the "brunch/RTS" headline. It feels soulless and stitched together for four reasons:

1. **It never says plainly what the game is above the fold.** The hero is a joke about drinks. "RTS" first appears in section 02.
2. **One story is told twice.** Section 01 (*Crónica*: foráneo → godínez → hipsters → mirreyes) and section 05 (the four ages) tell the same arc. The hero tells it a third time ("de aguas locas a cócteles").
3. **The jokes repeat until they are wallpaper.** *Cuarto de azotea* appears ×7, *aguas locas* ×5, *mirrey* ×5 and *renta* ×5, with "aguas locas en CU → cócteles en Pujol" stated almost word for word in both the hero and Age IV.
4. **Dev and roadmap notes leak into the marketing.** "Estos sistemas forman parte de las versiones públicas…", "El Ángel se reserva para un posible escenario de Reforma", "No necesitas invitación del equipo", "escaramuza local", and three separate concept-art-vs-real-capture disclaimers.

## 2. Copy corrections (Spanish)

| Where | Current | Issue | Fix |
|---|---|---|---|
| Hero h1 and Age IV | CÓCTELES / cócteles | The owner prefers the Mexican spelling *coctel / cocteles*, without the accent. Separately, the headline used the system font Impact, which iOS, Android and Linux do not ship. | *cocteles*. Self-host the display font (Anton) so headlines render the same everywhere. The new hero headline is "Del cuarto de azotea al rooftop con reservación" |
| Lore | "sólo acepta" | RAE: *solo* without an accent | *solo acepta* |
| Lore and Age II | “No es una invasión…” and «…» | Mixed quotation styles | Use « » everywhere |
| Ticker | "…PARA SU TANQUE LA ASAMBLEA…" | No separators, so four headlines read as one run-on sentence | Add separators: ` ★ ` between items |
| 04 eyebrow | "Bienvenido a la ciudad…" | Gendered | "Te damos la bienvenida a la ciudad donde todo queda a 40 minutos" |
| Bandos intro | "Toca una facción" | Assumes touch | "Elige una facción" |
| Polanco | "El Mirrey" | Capitalization differs from elsewhere | *el mirrey* |
| 01 / 05 eyebrows | "Crónica de…" ×2, and 05 has two subtitles | Repeated word, overloaded eyebrow | One short eyebrow per section |
| Age I stamp | "$ 1,800 / MES*" | Asterisk with no footnote | "$1,800/MES", or add the joke footnote ("*no incluye agua, luz ni dignidad") |
| Hero and Age IV | "Pujol" ×2 | A real restaurant used as a punchline; legal and goodwill risk, and it breaks the budget | "un menú degustación en Polanco" |
| Mapa | "La Roma, Narvarte y Copilco ya inspiran los mapas locales" vs. hero "Cinco mapas" | Reads as a contradiction: there are 5 solo maps, La Roma in three sizes plus Narvarte and Copilco | "Cinco mapas: La Roma en tres tamaños, Narvarte y Copilco" |
| Hero mini | "2 contra 2 frente a la IA · Salas privadas para dos" | Correct, but the modes are buried in fine print | Promote to a dedicated Modes section |
| FAQ | "La escaramuza local incluye…" | "local" is a dev term | "Cada partida incluye…" |
| FAQ | "El Ángel se reserva para un posible escenario de Reforma" | Roadmap leak | Cut, or "El Ángel tiene otros planes. Próximamente." |
| Footer | "Hecho con amor a la CDMX y sospecha razonable…" | Good; keep | — |

## 3. Information architecture

Current order: Hero → Ticker → 01 Lore → 02 How to play → 03 Factions → 04 City → 05 Ages → Poster CTA → 06 FAQ → Footer.
The nav lists four links in a different order from the page, and omits Ages and FAQ. On mobile the nav disappears entirely and there is no menu and no persistent CTA.

Proposed order, following the questions a player asks in sequence:

| # | Section | Player question | Notes |
|---|---|---|---|
| — | Sticky nav: links + **ES / EN** + "Jugar gratis" | — | A compact menu on mobile, with the CTA always visible |
| 1 | **Hero** | What is it? Can I play now? | Joke headline + one plain line ("Un RTS clásico en una CDMX de ficción…") + CTAs + "Gratis · Navegador y macOS" |
| 2 | **Gameplay proof** | What does it look like? | A trailer or looping capture plus 3–4 large real screenshots. This is the biggest gap on the page today |
| 3 | **Cómo se juega** | Is it a real RTS? | Build / Gather / Conquer, plus the 4 resources. Current section 02, tightened |
| 4 | **Las cuatro edades** (absorbs the current Lore section) | What makes it different? | The signature hook, told once. The Doctores illustration becomes the Age I visual |
| 5 | **Los bandos** | Who can I play? | Needs real per-faction art (see UI) |
| 6 | **Modos de juego** (new) | What can I play today? | Skirmish (5 maps, 3 AI levels), Campaign (3 chapters), Wonder, 2 v 2 vs AI, Private online rooms by code |
| 7 | **La ciudad** | Where is it set? | Split into "Jugable hoy" (5 maps) and "El resto de la ciudad (visión)", instead of fine print |
| 8 | **Final CTA poster** | — | Use a different line from the hero, not the logo slogan again |
| 9 | **FAQ** | Remaining doubts | Add: ¿Cuesta? ¿Windows? ¿En qué idioma está? ¿Cómo juego en línea con un amigo? ¿Se guarda mi progreso? ¿Necesito ser de la CDMX para entender? |
| — | Footer | Trust | itch.io, contact/press, socials, language switch, **one** satire/art disclaimer |

The ticker stays, but between the hero and the proof section, with separators and a pause control.

## 4. UI polish

**Systemic**
- Merge the three stacked style layers (base, "V2", "V3") that override each other with `!important` into one set of tokens: colors, one radius scale, one shadow, one button system. Today there are three CTA styles (red base overridden to teal, `.btn.alt`, `.age-cta`) and three corner radii (0, 5, 8–9 px).
- Self-host one display face (e.g. Anton or Bebas Neue, OFL licensed, with Latin Extended) and one text face. This fixes cross-device consistency and the accent issue together.
- Move inline `style="color:…"` spans to classes.
- Assets: about 3.3 MB of PNG and JPG. Serve WebP or AVIF with `srcset`, lazy-load everything below the fold, and give the hero a 2560 px source for retina.

**Section-level**
- **Hero, mobile:** the copy panel covers the baked-in logo, which is cropped to "TTLE FOR / ROMA". Either show the full logo above the panel or use a mobile-specific crop. On desktop, the text logo in the nav duplicates the art logo; hide it until the user scrolls.
- **Factions:** the portraits are crops of a concept sheet, so text labels and spreadsheet fragments appear inside the cards and look broken. Each faction needs one clean character or banner image (`regios-worker-build.png` hints at in-game sprites that could work).
- **City:** `cdmx-map.jpg` is a tileset sheet on black and reads as dev art. Replace it with a real La Roma capture showing Cibeles.
- **Ages:** the captures are small, dark and dominated by the HUD. Crop to the battlefield and enlarge them.
- **Epilogue box and poster:** the poster repeats the hero art and the logo slogan. Use a different capture or illustration.
- **FAQ:** a two-column `details` grid causes uneven row heights when items open. Use a single column at a 760 px max width.
- **Footer:** add real links.

**Accessibility and SEO**
- The ticker animates forever with no pause, which fails WCAG 2.2.2 (Pause, Stop, Hide). Add pause-on-hover/focus and a toggle, and mark the duplicated text `aria-hidden`.
- Add Open Graph and Twitter card tags with a share image, a favicon, `canonical`, `hreflang` (es-MX, en, x-default) and `VideoGame` structured data.

## 5. Bilingual strategy (landing and game)

### Landing: one template, two locale files, static output

```
landing/
  src/index.template.html     # markup with {{keys}}
  i18n/es-MX.json             # all copy, written natively
  i18n/en.json                # transcreated, same keys
  assets/
scripts/build-landing.mjs     # zero-dependency Node; writes dist/landing/{es,en}/index.html
```

- **Real URLs per language:** `/es/` and `/en/`, each with its own `<html lang>`, title, description, OG image and `hreflang` links. Search engines index both, and links can be shared per language.
- **The root `/`** uses a tiny Cloudflare Pages Function to read the saved choice (cookie), then `Accept-Language`, and returns a 302 to `/es/` or `/en/`. The default is es-MX.
- **Switcher:** "ES | EN" in the nav keeps the current section anchor, so you land on the same section in the other language.
- **Missing-key check:** the build fails if a key exists in one locale and not the other. It also warns when an English string is more than 40% longer than its Spanish counterpart, to catch layout breakage.
- The page keeps zero runtime dependencies and has no client-side swapping, so there is no flash of the wrong language.
- **Maintenance:** copy edits touch only JSON, and translators never see HTML. The glossary in `voice.md` is the term base.

### As built (2026-11-05)

The landing shipped with one change to the plan above. **`/` stays the canonical Spanish page and English lives at `/en/`.** There is no Pages Function and no automatic redirect: a dismissable notice offers the other language when the browser language doesn't match. This keeps every existing link and the itch.io backlinks working, needs no server code, and avoids redirecting search crawlers. Details are in [landing/README.md](../../landing/README.md).

### Game: Godot's built-in localization with gettext

Today the game is **mostly English** (menus, HUD, tooltips, campaign JSON) with Spanish proper nouns and a Spanish title card. The landing, meanwhile, is 100% Spanish. A Spanish speaker arriving from the landing currently gets an English game, and that is the first thing to fix.

1. **Wrap strings in `tr()`.** There are hundreds of hard-coded strings across `skirmish_main.gd` (~3.2k lines), `ui/battle_hud.gd` and `content/*.json` (campaign titles, objective labels). For JSON content, store translatable keys rather than prose, or translate fields by `msgctxt`.
2. **Use gettext `.po` files, not CSV.** Godot 4 generates a POT from scenes and scripts (Project Settings → Localization → POT Generation). PO gives translator context, plurals and fuzzy matching, and works with Poedit, Weblate or Crowdin if outside help is ever added.
3. **Locale selection.** First run follows `OS.get_locale()` (in the Web build that is the browser language). A language picker in the main menu and settings persists the choice to the existing local save. No query parameters are needed, which matters because itch.io's iframe doesn't pass them through.
4. **Layout safety.** Turn on Godot's built-in **pseudolocalization** (it lengthens and accents every string) in a QA pass to find clipped HUD labels. Spanish runs roughly 20–30% longer than English.
5. **Font check.** Confirm the HUD fonts cover á é í ó ú ü ñ ¿ ¡ « ».
6. **One source of truth.** Glossary terms (factions, ages, resources, modes) live once in the PO files and in `voice.md`. The landing JSON uses the same terms.

**Suggested order:** (a) Spanish landing fixes and the new IA; (b) the landing i18n build with EN; (c) game `tr()` extraction, which is mechanical but broad; (d) the es-MX game translation in the voice, with pseudolocalization QA; (e) the store page in both languages.

## 6. Domain: "battleforlaroma"

**Owner decision (2026-11-05): keep `battle-for-la-roma.pages.dev` for now.** The options below are kept for later.

- The `*.pages.dev` subdomain is fixed when a Cloudflare Pages project is created, and projects cannot be renamed. `battleforlaroma.pages.dev` is currently unclaimed: there is no DNS record for it.
- **Recommended: register `battleforlaroma.com`.** WHOIS on 2026-11-05 returned no match, so it appears available. Cloudflare Registrar sells at cost, about US$10/yr. Attach it to the existing Pages project as a custom domain and add `www`. Make `battleforlaroma.com` canonical, and 301 the old `pages.dev` host to it with a `_redirects` rule (Pages allows absolute-URL destinations). `.gg` and `.game` also appear free; `.mx` WHOIS gave no answer.
- **Free alternative:** create a new Pages project named `battleforlaroma`, deploy there, and 301 the old project to it.
- **itch.io:** the game slug (`/battle-for-la-roma-play`) can be changed in the project's edit page to `/battleforlaroma`. The `danybgoode.itch.io` part is the account name. Check whether itch redirects the old slug before changing it, because existing links point there.
- Any URL change must update `README.md`, `landing/README.md`, the landing CTAs and the release-evidence docs.
