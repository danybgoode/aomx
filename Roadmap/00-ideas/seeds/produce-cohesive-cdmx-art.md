---
title: "Produce cohesive CDMX game art"
slug: produce-cohesive-cdmx-art
status: raw
area: "02"
type: feature
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: 15
updated: 2026-10-21
intent_ask: proxy
hypothesis: "A coherent, readable production art system may make the existing La Roma battle feel like the intended game and help new players understand its units and objectives."
persona: "Players viewing and playing a Mexico City skirmish, including players unfamiliar with local references."
grounded: false
grounded_reason: "The art direction is approved, but no eligible cohort or blind comparison establishes its effect on first-match completion."
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

# Idea — Produce cohesive CDMX game art

The twelve 1536×1024 JPEG boards in `references/newArtWork/` show a compelling, warm isometric direction, but their panels are flattened concepts with inconsistent game mechanics and no production anchors. Build on the funded [battlefield art pack](../../02-civilizations-and-world/la-roma-battlefield-art-pack/README.md) and [owned-art pilot](../../02-civilizations-and-world/integrate-owned-art-library/README.md), rather than reopening either scope. Their existing manifest, export process and actual-scale checks are the starting point.

Refine a first visual production wave around the **playable Roma Norte/Cibeles match**: authored transparent terrain and transitions, Cibeles and surrounding architecture, readable four-faction unit silhouettes, resource sites, street props, construction/damage states and animation. Treat buildings, terrain, landmarks, civilians, factions, economy and props boards as art direction. Reuse or modify the owned isometric tiles and badger/boar/stag/wolf sources only where projection, scale, palette, frame coverage and gameplay role pass an in-engine test. Critters may remain view-only ambience; they do not acquire collision, economy or faction behavior from an image. The Cibeles silhouette must read as Cibeles; El Ángel belongs to a separate Reforma concept.

Shape this as an L bet with a pilot review after one ground tile, one building, one unit and the landmark at 100%/125% zoom. A later wave can expand to other districts, ages and factions. Production assets need per-source rights, tracked source, deterministic exports, transparent frames, pivot/footprint, directions, FPS, depth/occlusion rules, performance budgets and a Godot screenshot. Check dense fights, faction identification without color alone, and comprehension with familiar and unfamiliar players. No rule, collision, resource or age changes follow from the boards. See the [coverage review](../art-world-coverage-2026-10-21.md).
