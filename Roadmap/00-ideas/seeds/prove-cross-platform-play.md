---
title: "Prove cross-platform play"
slug: prove-cross-platform-play
status: raw
area: "09"
type: feature
appetite: null
underwritten_by: null
risk: high
epic: null
build_order: 22
updated: 2026-10-21
intent_ask: proxy
hypothesis: "One shared ruleset with device-appropriate controls may let players finish matches reliably on their chosen platform."
persona: "Desktop, browser and mobile RTS players."
grounded: false
grounded_reason: "Current evidence is desktop-centered; target-device performance and touch usability are unproven."
target_metric: match_completion
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

# Idea — Prove cross-platform play

Start desktop Web and touch feasibility probes early, then refine this production epic after representative gameplay and [interface contracts](complete-game-interfaces.md) exist. Use one simulation/content/save/protocol implementation for native Windows/macOS/Linux, desktop Web, native Android/iOS and supported mobile Web; supply desktop mouse/keyboard and designed touch interfaces, responsive HUD, graphics/performance profiles, save export/import and versioned builds. Test real devices and browsers for loading, long matches, storage, audio, input conflicts, asset memory, network origin/CORS and state equivalence; make specific support claims only from evidence. The current Restricted match route rejected a locally served Web origin during [multiplayer QA](../../../docs/multiplayer-remote-qa-2026-10-20.md); a Web export is not Web multiplayer proof. A simulated mouse tap is not a mobile RTS interface. Set minimum devices, battle size and performance budgets with the owner before funding platform release work. See the [GDD](../../../docs/design/GDD.md), [build path](../../full-game-build-path.md) and [coverage review](../art-world-coverage-2026-10-21.md).
