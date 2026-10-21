# Prove multiplayer and replays — QA wrap draft

The Restricted implementation is ready for owner functional QA. This is an undated draft; the epic remains in progress until its Definition of Done is evidenced and the owner accepts the play path. Actual cost, intent verdict and close date are recorded only at close.

## What reached Restricted QA

- A server-authoritative, invite-bound two-player match, 60-second recovery/no-result policy and participant-only fogged replay landed through PRs #56–#59. The deployed ARM64 image passed the unchanged 162-entity stress gate at its 1.0 CPU cap.
- Six scripted remote matches completed with matching terminal results and verified participant replays; four paired native macOS and Linux Godot clients. The signed owner-channel build was independently fetched, signature-checked, launched and visually inspected.
- The first owner join exposed a permanent database binding to a revoked invite. PR #62 changes the binding to one active code per installation and keeps retained replays available to a properly bound replacement code. Independent review found a second slot-assignment edge case; PR #63 keeps a replacement in the installation's original slot. Both fixes and migration 006 are on the Restricted host.

## What went well

- The unchanged state hash and benchmark fixture made the CPU-quota regression visible and gave the route/visibility optimization a precise pass condition.
- Separate host and download evidence prevented a merged commit or a Butler upload from being mistaken for a playable end-to-end result.
- Revocable codes, off-by-default admission and a current-version disabled-join probe kept the preview bounded between internal runs.

## What we learned

- Match admission reads a served flag snapshot until its process restarts; the operator runbook now requires a restart and denial probe after turning the preview off.
- Invite rotation affects replay authorization as well as join uniqueness. A revoked code must preserve its audit binding, while only a fresh active code bound to the same installation can read retained matches.
- A two-way 100 ms scripted terminal and a one-sided 150 ms/1% loss terminal are useful evidence, but neither completes the representative symmetric population-cap matrix.

## Gaps / follow-ups

- The owner owes the blind six-step downloaded-build walkthrough, including join, full result, recovery/expiry wording, replay controls, corrupt replay behavior, an excluded in-app receipt and revocation. The first join failed with `player_already_bound`; repeat it with fresh private codes when functional QA resumes.
- Complete the representative macOS/Linux network matrix at the playable population cap, including measured end-to-end RTT, command bursts and symmetric 150 ms/1% loss. Resolve Web origin policy if Web joins remain in scope.
- Keep admissions off and issue no second-person invitation until the remaining acceptance checks pass. There is no eligible retention cohort or observed later-day completion baseline.
