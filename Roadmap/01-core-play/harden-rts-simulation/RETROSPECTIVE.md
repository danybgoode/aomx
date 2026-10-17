# Harden the RTS simulation — retrospective

_Closed 2026-10-16 after owner browser download, save/resume and both terminal-route walkthroughs passed on the Restricted preview._

_Intent match: not separately scored. Actual API cost: not measured by the kit; original quote $50–$300 (L, n=0, wide)._

## Integrated result

- Sprint 1: One validated v1 content definition and semantic command/state contract preserve the current two-faction match. [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md) records the migration seam.
- Sprint 2: One local save slot, in-game resume and deterministic diagnostic replay cover version rejection, continuation, checkpoints and event deduplication. A Butler-fetched preview completed a rendered save/quit/reopen/resume check.
- Sprint 3: Building occupancy caching brought the 20×20/15, 32×32/83 and 48×48/163 debug matrix within predeclared route/tick budgets. Regios and Poblanos 700-tick hashes matched on macOS and Linux. [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) keeps multiplayer transport deferred and names the next experiment.

All code merged through [PR #39](https://github.com/danybgoode/aomx/pull/39) at `27661d2`; local Godot/Node/contract tests and Linux CI passed. Independent Codex review caught malformed replay input raising a runtime error; the fix and regression cases landed before merge. Signed Restricted preview `preview-27661d2a0900` became itch build `#2143645`. Anonymous access returned 404; Butler fetched byte-identical signed files from the Restricted channel.

The owner reported that the browser download, save/resume, a command-post win and a La Roma hold win all passed on that build. This closes the epic's real-build QA gate. The preview is restricted to the owner; no public release or real player cohort was created.

## What went well

The original Godot rules object stayed the authority, so the content and save seams did not require a second engine. Testing a larger crowd before choosing a pathing rewrite exposed a narrow static-occupancy bottleneck and gave a smaller fix with measurable benefit.

## What we learned

Cache invalidation after load matters as much as the hot path itself. Save data and measurement outbox need distinct lifecycles. The independent malformed-record finding shows why version and container checks must precede replay iteration. These points are promoted to [LEARNINGS](../../LEARNINGS.md).

## Follow-ons

- Dense fighter sprites overlap. Web/mobile, low-end hardware, release performance, generated maps and reconnect remain unproven. The provisional server-authoritative direction needs a later feasibility experiment; no network transport was built here.
- The current content schema represents the prototype only. Four resources, ages, prerequisites, fog and the full GDD rules need subsequent funded epics. No observed player cohort or Definitive Edition numerical parity is claimed.
