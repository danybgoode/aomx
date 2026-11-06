---
status: in-progress   # authoritative until the public release with both languages is verified
phase: Building
slug: game-localization
title: "Play the game in Spanish or English"
area: 09-platform-and-measurement
risk: medium
type: feature
sprints_total: 1
stories_total: 4
hypothesis: "Spanish-speaking players arriving from the Spanish landing page currently meet an English-first game. Offering the whole game in es-MX and English, chosen automatically and switchable in settings, should remove that mismatch without changing the rules."
target_metric: null
persona: "Mexican and other Spanish-speaking RTS players, plus English-speaking players, opening the public Web or macOS build."
grounded: false
grounded_reason: "Public builds send no play events, so no language-specific completion baseline exists to set a numeric target."
flag_key: null
---

# Play the game in Spanish or English

The owner asked on 2026-11-05 for the game and the landing page to be available in English and Spanish. The landing page shipped in [PR #114](https://github.com/danybgoode/aomx/pull/114). This epic covers the game. It went straight to build at the owner's request without a `refine` pitch, and this README records the scope after the fact.

## Scope

- Every player-facing string in the public Web and macOS builds reads in es-MX or English: home, setup, campaign, HUD, commands, notices, results and settings.
- The first launch follows the device or browser language. A Language / Idioma picker on the setup screen and in in-match settings switches it live and remembers the choice.
- Wording follows the [voice and style guide](../../../docs/brand/voice.md) and its glossary. English uses the glossary's names (Food, Materials, Varos, Land; Out-of-Towner, University, Godín and Gentrification ages).
- **Rules and multiplayer stay unchanged.** `skirmish.gd`, `rules_content.gd` and `content/skirmish.v1.json` are untouched, so the simulation hash and the public match host stay compatible.

Not in scope: languages beyond es-MX and English, voiced audio, store-page text, and the Restricted alpha operator wording beyond translation.

## How it works

See [game/README.md § Localization](../../../game/README.md#localization). In short, plain Control text is translated by Godot's auto-translate, runtime text calls `tr()`, and ids go through `GameText.name()`. The catalogs are `game/i18n/{es,en}.po`, and `npm run i18n:check` guards them in CI.

## Definition of Done

- [x] Catalog tooling: extract, sync and check, run in `npm test`
- [x] Spanish and English catalogs cover every extracted string, with placeholders in order
- [x] Godot `localization_test.gd` proves no English leaks into the Spanish setup, HUD or settings, and that live switching works
- [x] The public export refuses dirty trees and verifies both catalogs inside the Web and macOS packages
- [x] Public Web and macOS builds from the merged commit are uploaded and verified in both languages ([release record](../../../docs/release/bilingual-game-release-2026-11-05.md))
- [ ] Owner read-through of the Spanish copy in a real match
