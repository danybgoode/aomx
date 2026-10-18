# Integrate the owned art library — retrospective

_Draft until downloaded-build acceptance passes and the epic closes. The dated QA record is in [Sprint 3](sprint-3.md)._

## Built

A 32-export traced pipeline now covers selected owner-supplied tiles, four-direction boar idle frames and an isolated transparent command-post derivative. The Godot pilot displays all three at 100% and 125%. One flower tile is a view-only prop in the current match; no critter behavior, terrain passability or concept-board mechanic was added.

## Verified

Manifest hashes, dimensions and the 1 MiB decoded RGBA cap passed. The selected exports sum to 220,032 decoded RGBA bytes. The Godot art pipeline test, match client and persistence checks, Node suite and skirmish ingest contract passed locally. The rendered pilot and match were inspected on the development Mac; the pilot returned one 119 FPS debug sample at 1280×800. A friendly command post remained selectable by its visible body. See [pipeline and screenshot](../../../docs/art/owned-art-pipeline.md).

The source commit `0d2b90f67f91` passed GitHub checks in [PR #42](https://github.com/danybgoode/aomx/pull/42) and reached `master` in merge commit `399ea2d54cfb3b898b8f8176ba49ed9254a483c9`. The signed macOS archive SHA-256 is `04d1125e537f40b1cba3b9940aa909176b4b7954094141f7a23ab76c3c522b61`. It was published to the Restricted itch channel `mac-private-alpha` as `preview-0d2b90f67f91`, Butler build `#2146053`. An authenticated Butler fetch reproduced the app contents; strict code-signature verification passed. The fetched app opened, its menu showed the expected build ID, and the flowers rendered in a Regios match at normal zoom. This is a verified private preview, not a public game release or a deployment caused by the merge.

The owner reviewed the 100%/125% comparison and chose to keep the boar, raised tiles and concept command post in the pilot. The flower prop is the only new match asset. Raised sidewalls do not join flat ground cleanly, and the boar needs more contrast at match scale.

## Open evidence

During the downloaded-build check, the `preview-0d2b90f67f91` app in Downloads was checked again. A Regios match rendered the owned flowers at normal zoom; worker gathering, post construction, fighter recruitment and combat accepted commands. It ended in a command-post loss at 02:08, so it does not count as a victory-route pass. Saving and resuming that match in-process worked, but after terminal loss the saved slot correctly reported the match was finished. A separate unfinished Poblanos match was saved at 00:13, quit, reopened from the downloaded app, and resumed at the same match time. The local outbox held one pending, `test_account: true` `match_started` event for that Poblanos match after resume, without a duplicate start; the Regios loss had one start and one completion, both pending and test-tagged. No invite code was entered and no sync was attempted.

The full downloaded-build wins for both factions and both victory routes remain unchecked, as does synced event receipt behavior. Keep the epic `in-progress` and Sprint 3 open until the agreed match acceptance is recorded. The live Hub should show **QA** after a fresh roadmap push: PR #42 merged and Sprint 3 is active. The epic README status is the completion source of truth. Existing first-match completion has no real baseline. Pending sync without an invite code is expected for private test traffic and is not evidence of an art regression.
