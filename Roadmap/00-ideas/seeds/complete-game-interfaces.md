---
title: "Complete the game interfaces"
slug: complete-game-interfaces
status: raw
area: "02"
type: feature
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: 18
updated: 2026-10-21
intent_ask: proxy
hypothesis: "A coherent interactive HUD and frontend may let players choose, understand and finish a match without learning the developer preview controls."
persona: "New skirmish and multiplayer players using mouse/keyboard, then supported touch devices."
grounded: false
grounded_reason: "The existing HUD is builder-verified, but uncoached comprehension and platform-specific completion evidence are open."
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

# Idea — Complete the game interfaces

Extend the funded [readable battlefield HUD](../../02-civilizations-and-world/readable-battlefield-hud/README.md) after its owner checks. Refine an interactive frontend and gameplay UI system from `full-hud.jpg` and `menus.jpg`: compact resource/age/population bar, contextual selection and command grid, production/research queues, objective and fog-aware minimap, alerts, save/replay, faction/map/skirmish setup, settings, credits and clear victory/defeat. Keep alpha invite, support ID and sync diagnostics reachable in settings without filling the permanent battle HUD. UI reads simulation state and issues semantic commands; concept panels must not create diplomacy, culture, tourism or extra resources by implication.

First prove desktop keyboard/mouse flow and readable in-match states at 1024×700 and 1280×800, with uncoached tasks and keyboard/accessibility review. Design mobile touch layout and gestures alongside it, but put native/mobile-Web device proof and performance gates in [cross-platform play](prove-cross-platform-play.md). Campaign chapter/dialogue views wait for [scenario work](create-campaigns-and-scenarios.md). Localize text outside artwork and provide scalable type, non-color-only state, reduced-motion and caption hooks. See the [coverage review](../art-world-coverage-2026-10-21.md).
