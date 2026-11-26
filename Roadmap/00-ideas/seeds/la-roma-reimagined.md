---
title: "La Roma, reimagined: the lore as mechanics, and La Roma Pocket"
slug: la-roma-reimagined
status: scaffolded
area: "04"
type: feature
appetite: null
underwritten_by: wave-2026-11
risk: high
epic: 01-core-play/first-match-that-works
build_order: 25
updated: 2026-11-26
---

# La Roma, reimagined

**Review and design:** [`00-ideas/sketches/mobile-reimagined/index.html`](../sketches/mobile-reimagined/index.html) (open locally). It holds the findings, the six formats scored, and the playable Pleito prototype.

## Problem

The review of public Web build `html5-public #2310032` (2026-11-25) found:

- **The first match fails.** A newcomer lost the default match at 3:09 without a single fight. The AI took Cibeles with a 75-second hold while the player was still telling three identical stalls apart.
- **The lore isn't in the game.** It's on the landing page (rooftop room, aguas locas, the godín, the mirrey's tank at valet). The game has "Worker", "Melee fighter", "Registry" and "carry 5". Factions are 1–2 stat tweaks, there are no unique units, no city systems, and the campaign is a tutorial checklist.
- **The scope is a thin AoE2.** 5 units, 5 buildings, 5 techs and pop 24, so it can't win on AoE2 fidelity, and the GDD's pillar 3 ("Mexico in the mechanics") is unbuilt.
- **Mobile is the desktop HUD shrunk.** The battlefield gets about 15% of a portrait phone screen.
- **There's no reason to return,** although the North Star is returning commanders.

## The pitch (the owner funded all of it, 2026-11-26)

Two products, one universe:

- **La Roma RTS** (Web and desktop) keeps the RTS. It fixes the first match, then makes the city the mechanics: archetype units, rent, the quincena, rush hour, the Metro, faction verbs, city events, and a Cibeles you fight over.
- **La Roma Pocket** (mobile Web first, then the stores) is a portrait, one-thumb hub of five games on the same canon: **Pleito de Vecindad** (auto-battler, the hero mode), **Hora Pico** (roguelite tower defense), **Bronca en la Glorieta** (live lane PvP), **La Roma en 30 Turnos** (micro turn-based 4X) and **La Mudanza** (packing puzzle). The **Del cuarto de azotea al rooftop** meta and idle layer, plus **Semestres y colonias**, give players a reason to come back on a later day.

### Principles every epic follows

1. **The satire is the mechanics.** Urban archetypes and the gentrification machine are classes anyone can field. Factions are playful strategies, never claims about real regional people (AGENTS.md).
2. **One canon.** Every mode reads archetypes, traits, events, ages, rent and rivals from `game/content/canon.v1.json` (#26). No mode hard-codes lore.
3. **Readable without the joke.** Every rule has a plain line beside the joke line.
4. **Everything is deterministic.** Each simulation is fixed-tick integer math with headless and cross-platform hash tests. That is what makes ghosts, server verification, replays and clips possible, and what keeps leaderboards honest.
5. **One thumb on Pocket:** taps only, targets of at least 44 pt, and portrait.
6. **Unlocks never sell power.** Money buys cosmetics and the pass only (D8).
7. **Every mode is measured the same way:** `match_started` and `match_completed` with `mode` through the existing outbox.

## Architecture

- **One Godot project (`game/`), two shells (D2).** The RTS stays where it is. Pocket lives in `game/pocket/` with a hub and one folder per mode (`pleito/`, `hora_pico/`, `bronca/`, `turnos/`, `mudanza/`). Each mode has a pure-logic `sim.gd` (or `battle.gd`) and a view scene. New export presets: Pocket Web, Pocket Android, Pocket iOS.
- **Shared code:** `game/canon.gd` (loader and validator), the profile and save service (extending the portable saves), the funnel outbox with `mode`, the i18n catalogs (`npm run i18n:check`), and the owned art pipeline.
- **Server (D7):** extend the existing Node match host with `src/pocket/` (ghost boards, daily seeds, leaderboards, colonias, seasons, async turns) on the same Postgres via `db/007_pocket*.sql`. Submitted runs are re-simulated by the existing headless Godot worker before they rank. Lane PvP uses the match host's relay. Every mode is gated by a `pocket.<mode>_enabled` Golden Frijoles flag.
- **Versions:** rules changes bump the content version. The host is redeployed on the same version as the clients (D1).

## Economy and strategy concepts → where they live

| Concept | What it does | RTS | Pocket |
|---|---|---|---|
| Renta | Upkeep that rises every age; Terrenos lower it | #30 | Pleito #28 (rent per age), 30 Turnos #34 (per city), meta #29 (sink) |
| Quincena | Periodic income pulse | #30 (90 s from Edad Godín) | Pleito Contadora and event #28, weekly chest #29, Pase #36 |
| Tanda | Interest on saved Varos (1 per 5, max 2) | | Pleito #28 |
| Tarjetazo and valet | Mirrey buys a neutral building / Mirreyes +dmg and +Varos on a win | #32 | Pleito #28 |
| Hora pico and Metro | Rush-hour slowdown on avenues; Metro garrison travel | #30 | Pleito event #28, Hora Pico waves #31 |
| Plusvalía | Buildings flip neutral blocks; enemy buildings inside lose pop cap | #32 | 30 Turnos territory #34 |
| Dollarized Varos | Regios' swinging exchange rate | #32 | Regios trait effects |
| Tequio · Bocinas · Talavera and Mole | Faction verbs (co-op build, spreading area claim, long-cook buff) | #32 | Faction traits #26, #28 |
| Junta · Marcha · Broker render | Archetype verbs (stun, road block, conversion or area damage) | #32 | Pleito #28, Hora Pico #31, Bronca #33 |
| Age-up choice cards | Pick 1 of 2 at each age | #30 | 30 Turnos #34 |
| City events | Marcha en Reforma, Lluvia de las 5, Obra eterna, Se fue la luz, Quincena, Aguas locas… | #32 | Every mode, from the canon #26 |
| Cibeles control | Vision → income → win, fighters only | #25 (gate), #32 (escalation) | Bronca king post #33, weekend contest #36 |
| Depósito | Lives in a run | | Pleito #28, Hora Pico #31 |
| Unlocks by apartment stage | Archetypes unlock, never stats | | #29 |

## Slices (the build order)

| # | Epic | Area | Destination | Needs |
|---|---|---|---|---|
| 25 | [A first match that works](../../01-core-play/first-match-that-works/README.md) | 01 | complete-solo-battle | none |
| 26 | [The La Roma canon](../../02-civilizations-and-world/la-roma-canon/README.md) | 02 | fight-for-la-roma | none |
| 27 | [Pocket shell and services](../../04-pocket-la-roma/pocket-shell/README.md) | 04 | pocket-la-roma | #26 S1 |
| 28 | [Pleito de Vecindad](../../04-pocket-la-roma/pleito-de-vecindad/README.md) | 04 | pocket-la-roma | #26, #27 |
| 29 | [Del cuarto de azotea al rooftop](../../03-multiplayer-and-retention/del-cuarto-al-rooftop/README.md) | 03 | reasons-to-return | #27 |
| 30 | [RTS lore pass](../../02-civilizations-and-world/rts-lore-pass/README.md) | 02 | fight-for-la-roma | #25, #26 |
| 31 | [Hora Pico](../../04-pocket-la-roma/hora-pico-td/README.md) | 04 | pocket-la-roma | #26, #27 |
| 32 | [RTS city depth](../../01-core-play/rts-city-depth/README.md) | 01 | full-depth-rts | #30 |
| 33 | [Bronca en la Glorieta](../../04-pocket-la-roma/bronca-en-la-glorieta/README.md) | 04 | pocket-la-roma | #27, #28 |
| 34 | [La Roma en 30 Turnos](../../04-pocket-la-roma/la-roma-en-30-turnos/README.md) | 04 | pocket-la-roma | #26, #27 |
| 35 | [La Mudanza](../../04-pocket-la-roma/la-mudanza/README.md) | 04 | pocket-la-roma | #26, #27 |
| 36 | [Semestres y colonias](../../03-multiplayer-and-retention/semestres-y-colonias/README.md) | 03 | reasons-to-return | #29, two pocket modes |
| 37 | [Pocket in the stores](../../09-platform-and-measurement/pocket-store-launch/README.md) | 09 | accessible-cross-platform-release | #28, #29, D5, D8, D9 |

71 stories across 27 sprints. The epics are deliberately chunky because they get built fast. Later sprints may be re-cut once the sprint before them ships, and the re-cut is recorded in the epic README.

### Sequencing

```
RTS track     #25 first match ──► #30 lore pass ──► #32 city depth
                    ▲                 ▲
Canon         #26 canon ──────────────┤
                    │                 │
Pocket track        └► #27 shell ──► #28 Pleito ──► #33 Bronca
                                  ├► #31 Hora Pico
                                  ├► #34 30 Turnos
                                  └► #35 La Mudanza
Return loop             #27 ──► #29 apartment meta ──► #36 semestres y colonias ──► #37 stores
```

#25 and #26 can run in parallel. Once #27 ships, the pocket modes are independent of each other and can run in parallel too. Only #33 reuses #28's battle code.

## Decisions: the defaults builders use unless the owner overrides them

| | Decision | Default | Needed by |
|---|---|---|---|
| D1 | Rules changes break rooms for older clients | Bump the content version, redeploy the host the same day, migrate saves or label them incompatible | #25, #30, #32 |
| D2 | Code layout | One Godot project, two shells, shared canon | #27 |
| D3 | Cultural portrayal | The builder ships each mode behind its flag; public release follows the owner's read-through of the roster and barks | every epic |
| D4 | Pocket identity and names | Pseudonymous install id, no accounts; colonia names and emblems from a preset list (no free text, so no moderation) | #27, #36 |
| D5 | Do pocket runs count toward the North Star? | **Owner decision** (it changes the agreed definition). Until then, emit events test-tagged with `mode` and report per mode | #27, #37 |
| D6 | Where Pocket lives on itch | Its own mobile-first itch page, "La Roma Pocket" | #27 |
| D7 | Hosting | Extend the existing ARM64 host and Postgres, no new vendors; watch PvP cost | #27, #33 |
| D8 | Money | Cosmetics and the pass only. No ads, no paid power, no paid loot boxes; prices and premium currency set by the owner; store billing on native only, Web free. **Owner yes before #37 S1** | #35, #37 |
| D9 | Store accounts and iOS signing | The owner provides them (iOS signing is unavailable today); Android first | #37 |
| D10 | Voice | Barks are text first; voiced audio later | #26 |

Escalate anything else that changes core rules, audience, cultural portrayal, privacy, spending, deployment or the North Star ([Ways of Working](../../WAYS-OF-WORKING.md#escalate-dont-guess)).

## Done means (every epic)

Merged to `main` and shipped in a real build:

- **RTS:** public Web and macOS builds through the release runbook, with `npm run public:verify` passing.
- **Pocket:** Pocket Web on its itch page, verified on iPhone Safari and Android Chrome.
- **Server:** the host redeployed when server code or migrations changed.

Every epic also needs ES and EN, the owner's read-through, then `status: shipped` and a board sync. A merge alone isn't shipped.

## Reads (not kill gates, since all of it is funded)

For each mode, record first-run completion, later-day completion and clip shares once events are eligible (D5). Compare them against the provisional 15% later-day target. A weak read re-cuts the next sprint of that mode; it doesn't stop the wave.
