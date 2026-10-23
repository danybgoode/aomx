---
epic: build-large-la-roma-battlefield
sprint: 3
title: "Complete match proof"
risk: high
phase: Locking architecture
stories_total: 1
stories:
  - id: S3.1
    title: "Finish both routes on the large map"
    as_a: "classic RTS player"
    i_want: "a complete large-map match against a fair opponent"
    so_that: "exploration and expansion lead to a finishable strategy game"
    risk: high
    status: planned
---

# Build a large La Roma battlefield — Sprint 3: Complete match proof

**Status:** ⬜ Planned — follows resource and movement verification

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
