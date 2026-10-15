# Finish a solo skirmish — Retrospective

_Open: implementation reached `master` through integration PR #12; the follow-up readability slice and downloaded-build sync check are being finished. A public game release remains open._
_Intent: owner completed a solo match and reported that the game works well; readability and action feedback needed refinement._
_Quote vs actual: $20–$120 API estimate; actual unavailable from local transcript accounting._
_Crew: Codex builder; independent agent reviewed the funnel event path. No GitHub review recorded yet._

## What is built locally

- Sprint 1: mirrored economy, recruitment building and worker/melee/ranged production.
- Sprint 2: validated combat orders, deterministic damage and command-post destruction.
- Sprint 3: authored opponent, win/loss/draw, restart and test-tagged offline start/result events.

## What went well

The fixed-tick simulation and existing outbox made the result path testable without a hosted backend. The Godot-to-Node check keeps test traffic out of public cohorts.
The owner could play a complete downloaded match on one Mac, revealing a presentation issue that headless checks could not catch. A separate rendered Godot window let the builder check board scale, selection, gather feedback and fullscreen without interrupting the owner's running alpha.

## What we learned

Later-day opens need a new event ID; unresolved earlier receipts must stop ordered upload. The 12-unit route and tick measurements support continuing Godot for another bounded slice.
Readable controls and visible order outcomes are part of the playable loop; passing simulation rules alone did not make early actions clear on the owner's display.

## Gaps / follow-ups

Check the new downloaded build on the owner's display and sync a test-tagged result through the private invite. Establish a public release rail, measure crowd movement and release-build frame time, and finish the separate funnel epic's real cohort reconciliation. An isolated authenticated ingest is staged on the VM. No launch baseline exists.
