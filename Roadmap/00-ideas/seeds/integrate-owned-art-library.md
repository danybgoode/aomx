---
title: "Integrate the owned art library"
slug: integrate-owned-art-library
status: raw
area: "02"
type: feature
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: 9
updated: 2026-10-16
intent_ask: verbatim
hypothesis: "Owner-supplied tiles, sprites and Mexico City concepts may make the playable battle more distinctive and readable without changing its rules."
persona: "Players trying the existing La Roma battle and later maps, including players unfamiliar with local references."
grounded: false
grounded_reason: "No eligible first-match cohort or blind comprehension result isolates the effect of these new assets."
target_metric: first_match_completion
target_from: null
target_to: null
read_date: null
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
intent_match: null
---

# Idea — Integrate the owned art library

> Theres also new art work to use in references/newArtWork
> Remember that we also have the whole references/critters and references/isometric tileset to use as they are very high quality.

The owner confirmed commercial rights to all three sets on 2026-10-16. After the existing [battlefield art v0.1](../../02-civilizations-and-world/la-roma-battlefield-art-pack/README.md) and [HUD](../../02-civilizations-and-world/readable-battlefield-hud/README.md) owner QA, refine a follow-on art production epic. Inventory provenance, frame/anchor conventions and the current 48×24 projection; build a rendered scale pilot using selected `isometric tileset` tiles and one animated critter; derive or author isolated transparent sprites from the `newArtWork` direction, not a flattened map image; then integrate selected production assets through the manifest with palette, readability and memory checks. The critters need an approved gameplay or ambient role before they enter matches. Preserve simulation footprints, picking, collision and objectives. Record per-asset source/export metadata and owner visual review, then play a complete match at normal zoom. The [inventory](../../../docs/art/reference-inventory.md) describes the files and the [GDD](../../../docs/design/GDD.md) sets the visual target. This can run beside the early simulation foundation if it stays view-only; it does not replace that dependency for broader gameplay systems.
