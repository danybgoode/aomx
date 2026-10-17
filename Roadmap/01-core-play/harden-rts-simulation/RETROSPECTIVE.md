# Harden the RTS simulation — provisional retrospective

_Close pending: owner browser download and two terminal-route walkthroughs on the Restricted preview._

_Intent match: pending owner verdict. Actual API cost: not stamped by the kit; original quote $50–$300 (L, n=0, wide)._

## Integrated result

- Sprint 1: One validated v1 content definition and semantic command/state contract preserve the current two-faction match. [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md) records the migration seam.
- Sprint 2: One local save slot, in-game resume and deterministic diagnostic replay cover version rejection, continuation, checkpoints and event deduplication. A Butler-fetched preview completed a rendered save/quit/reopen/resume check.
- Sprint 3: Building occupancy caching brought the 20×20/15, 32×32/83 and 48×48/163 debug matrix within predeclared route/tick budgets. Regios and Poblanos 700-tick hashes matched on macOS and Linux. [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) keeps multiplayer transport deferred and names the next experiment.

All code merged through [PR #39](https://github.com/danybgoode/aomx/pull/39) at `27661d2`; local Godot/Node/contract tests and Linux CI passed. Independent Codex review caught malformed replay input raising a runtime error; the fix and regression cases landed before merge. Signed Restricted preview `preview-27661d2a0900` became itch build `#2143645`. Anonymous access returned 404; Butler fetched byte-identical signed files from the Restricted channel.

## What went well

The original Godot rules object stayed the authority, so the content and save seams did not require a second engine. Testing a larger crowd before choosing a pathing rewrite exposed a narrow static-occupancy bottleneck and gave a smaller fix with measurable benefit.

## What we learned

Cache invalidation after load matters as much as the hot path itself. Save data and measurement outbox need distinct lifecycles. The independent malformed-record finding shows why version and container checks must precede replay iteration. These points are promoted to [LEARNINGS](../../LEARNINGS.md).

## Open close-out and follow-ons

- The owner still needs to download the current build through the browser while signed in, then finish both full manual victory-route walkthroughs. Builder CLI fetch and rendered resume are recorded in [the QA guide](../../../docs/alpha-local-qa.md) and do not replace that owner gate.
- Dense fighter sprites overlap. Web/mobile, low-end hardware, release performance, generated maps and reconnect remain unproven. The provisional server-authoritative direction needs a later feasibility experiment; no network transport was built here.
- The current content schema represents the prototype only. Four resources, ages, prerequisites, fog and the full GDD rules need subsequent funded epics. No observed player cohort or Definitive Edition numerical parity is claimed.
