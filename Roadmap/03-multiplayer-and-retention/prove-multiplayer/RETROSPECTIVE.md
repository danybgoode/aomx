# Prove multiplayer and replays — retrospective

_Closed 2026-10-22 after the live Restricted host, independently fetched signed owner build and owner match/replay walkthrough passed._

_Intent match: one-human technical feasibility proved; two-human social value and retention remain unmeasured. Actual API cost was not metered by the kit; original quote $50–$300 (L, n=0, wide)._

## What reached Restricted QA

- A server-authoritative, invite-bound two-player match, 60-second recovery/no-result policy and participant-only fogged replay landed through PRs #56–#59. The deployed ARM64 image passed the unchanged 162-entity stress gate at its 1.0 CPU cap.
- The owner completed a signed downloaded-build GUI match and fogged online replay against a native Linux client. On the current host, native Mac/Linux baseline and symmetric impaired full matches reached matching results and verified replays. A disposable copy of the deployed image passed the 50-entity native network matrix at baseline, 100 ms and 150 ms/loss.
- The first owner join exposed a permanent database binding to a revoked invite. PR #62 changes the binding to one active code per installation and keeps retained replays available to a properly bound replacement code. Independent review found a second slot-assignment edge case; PR #63 keeps a replacement in the installation's original slot. Both fixes and migration 006 are on the Restricted host.
- PR #65 repaired a waiting-room timestamp bug and excluded receipt labels. PRs #67/#68 added bounded offline participant replay files, clear bad-file errors and a visible replay control. Corrected owner-only itch build #2181405 was independently fetched, byte-compared, signature-checked and GUI-tested for valid and bad files. The owner opened/paused/resumed a valid file, saw the unsupported-version error and saw admission closed on the final GUI retry.

## What went well

- The unchanged state hash and benchmark fixture made the CPU-quota regression visible and gave the route/visibility optimization a precise pass condition.
- Separate host and download evidence prevented a merged commit or a Butler upload from being mistaken for a playable end-to-end result.
- Revocable codes, off-by-default admission and a current-version disabled-join probe kept the preview bounded between internal runs.

## What we learned

- Match admission reads a served flag snapshot until its process restarts; the operator runbook now requires a restart and denial probe after turning the preview off.
- Invite rotation affects replay authorization as well as join uniqueness. A revoked code must preserve its audit binding, while only a fresh active code bound to the same installation can read retained matches.
- A paced local benchmark and a four-starting-entity impaired full match measured different risks. The population-cap network matrix needed a disposable seeded copy of the deployed service plus native clients; configured impairment and observed HTTP RTT/drops were recorded separately.

## Boundaries / follow-ups

- Web origin support is outside this Restricted native slice and remains with the cross-platform seed.
- Keep admissions off until a separately approved invitation. The owner was the only human player; the Linux client was automated. There is no eligible retention cohort or observed later-day completion baseline. The owner's GUI denial came from the disabled admission flag; revoked-code behavior has separate tests and live binding evidence.
