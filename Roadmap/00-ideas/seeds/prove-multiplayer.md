---
title: "Prove multiplayer and replays"
slug: prove-multiplayer
status: raw
area: "03"
type: feature
appetite: null
underwritten_by: null
risk: high
epic: null
build_order: 14
updated: 2026-10-16
intent_ask: proxy
hypothesis: "Reliable shared matches and replays may give RTS players more reasons to complete and repeat games together."
persona: "RTS players who want fair team or competitive matches."
grounded: false
grounded_reason: "No player demand, network prototype or cross-platform determinism evidence exists yet."
target_metric: return_to_match
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

# Idea — Prove multiplayer and replays

Use the early synchronization investigation from [simulation foundation](harden-rts-simulation.md) to choose lockstep or another authoritative model with measured evidence, then refine this into a networked match epic after rules and content stabilize. Include semantic command protocol, player slots/teams, version negotiation, state checks, desync diagnosis, reconnect policy, replay compatibility, result integrity and at least one real two-client/server full match. Test network delay/loss and cross-platform hashes or authoritative reconciliation on declared devices. Do not equate Godot's fixed tick with deterministic multiplayer, and do not count client-reported local results as trusted public results without the existing backend acceptance contract. Matchmaking/ranked policy remains an owner decision.
