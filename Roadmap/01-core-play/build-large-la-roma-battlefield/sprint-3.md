---
epic: build-large-la-roma-battlefield
sprint: 3
title: "Complete match proof"
risk: high
phase: In review
stories_total: 1
stories:
  - id: S3.1
    title: "Finish both routes on the large map"
    as_a: "classic RTS player"
    i_want: "a complete large-map match against a fair opponent"
    so_that: "exploration and expansion lead to a finishable strategy game"
    risk: high
    status: in-progress
---

# Build a large La Roma battlefield — Sprint 3: Complete match proof

**Status:** 🟦 In review — build and integration checks underway; signed download, four outcomes and owner/uncoached reads remain open

### Story 3.1 — Finish both routes on the large map

**As a** classic RTS player, **I want** a complete large-map match against a fair opponent, **so that** exploration and expansion lead to a finishable strategy game.

**Acceptance:** In a signed downloaded Restricted preview, both factions finish by Conquest and by uncontested La Roma hold against the AI. At least one match includes save/resume and replay, with one test-tagged result sync if the connected ingest supports the new content version. The current maps still load and old saves fail safely or resume per the version contract. The owner records an accept/revise decision on map size, resource spacing, match pacing and bicitaxi readability. An uncoached player unfamiliar with CDMX explains the scout's job and both win routes. A ten-minute representative owner-Mac release export records route/tick/frame/memory against D7's budgets. No public invitation or eligible-cohort claim follows.

**Risk:** high — full rules, persistence, performance and versioned Restricted release.

## Sprint QA

- **Deterministic:** full Godot rules/content/client, save/replay, two victory routes, cross-platform hash and Node game-to-ingest contract.
- **Rendered:** 1024×700 and 1280×800 default/enlarged HUD with combat, expansion, objective, result and bicitaxi selection.
- **Gate:** independent high-risk review, required CI, representative release-build budget, signed download verification and owner/uncoached walkthrough record.

## Sprint 3 — Smoke walkthrough

Environment: signed Restricted macOS preview, record its exact build ID and download source.

1. As Regios, scout and expand, then destroy the enemy's final command post. → One Conquest result appears and the match completes once.
2. As the other faction, scout and expand, then hold La Roma uncontested. → The objective progress and one hold result are clear.
3. Repeat the opposite faction × victory combinations, including one save/quit/resume and one replay. → All four outcomes complete, restore preserves identity and replay reproduces the finish.
4. Sync one test-tagged result and inspect its receipt. → The ingest accepts only a supported version and public eligible counts remain unchanged.
5. Ask one uncoached player to identify the bicitaxi's purpose, a distant expansion and both win routes. → Record exact answers and any confusion, without supplying CDMX context first.

Record every failure by step and build ID. Only the owner can close the final feel and human-acceptance checks.

**2026-10-24 builder checkpoint:** New-map conquest and uncontested district outcomes pass deterministic checks. An independent reviewer also completed a legal district hold after moving from home and observed standard-AI conquest on the 96×96 map. The AI-enabled mixed 6000-tick probe passed route p95 4.802/12 ms and tick p95 1.378/8 ms with two real combat casualties. An isolated release export passed frame p95 at both target windows (26.141/33.3 ms at 1280×800; 25.720/33.3 ms at 1024×700), with process RSS below 768 MiB. See [QA evidence](../../../docs/world/large-la-roma-qa-2026-10-23.md). CI, signed Restricted fetch, four downloaded-app outcomes, owner feel decision, one event receipt and uncoached recognition remain open.

**2026-10-24 Restricted checkpoint:** [PR #87](https://github.com/danybgoode/aomx/pull/87) merged after Project checks and CodeQL passed. `preview-cdab7b08f046` is ready as Butler build #2200926 on a separate Restricted `mac-large-map-pilot` channel; a fresh authenticated fetch matched the signed source app byte for byte and started headlessly. The existing online-compatible channel was preserved because the VM still runs an earlier game version. The four owner-driven outcomes, map-feel decision, uncoached recognition and a compatible excluded event receipt remain open. The [QA record](../../../docs/world/large-la-roma-qa-2026-10-23.md) gives the exact archive hash and limits.
