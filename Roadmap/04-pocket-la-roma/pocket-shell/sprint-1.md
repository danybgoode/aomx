---
epic: pocket-shell
sprint: 1
title: "The shell"
stories_total: 3
---

# La Roma Pocket: the shell and its services · Sprint 1: The shell

**Status:** ⬜ Planned

## Stories

### S1.1 Portrait hub and the one-thumb kit

As a phone player, I open a portrait hub with a tile per mode (locked by flag until its epic ships), settings and language. The UI kit has card, bench slot, board cell, bottom sheet and notice, all with targets of at least 44 pt. There are new export presets: Pocket Web, Pocket Android and Pocket iOS. Done when it holds 60 fps on iPhone 15 Pro Safari and a mid-range Android Chrome, and the RTS export is unchanged.

### S1.2 Profile, saves and the funnel

As a player, my pocket progress survives: a local profile keyed to the install id, with save export and import reusing the portable-save format. Every mode emits `game_opened`, `match_started` and `match_completed` with `mode` and content version through the existing outbox. Events stay test-tagged until D5 is decided.

### S1.3 Pocket Web on its own itch page

As a phone player, I can play from a link: a mobile-first itch page for La Roma Pocket (D6). `npm run pocket:export` and `npm run pocket:verify` extend the public release runbook.
