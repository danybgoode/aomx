# Audio and effects QA

**State:** Builder checks passed locally; signed downloaded-build, owner and two uncoached recognition reads are open. No eligible cohort or numeric completion lift is claimed.

## Builder evidence · 2026-10-23

- Godot 4.7.2: `game/tests/presentation_cues_test.gd` passes cue deduplication, cooldown, priority, fog suppression, accepted/rejected order, mute, gather/delivery, construction, objective, friendly damage, reduced effects and terminal one-shot/baseline checks.
- Existing `game/tests/skirmish_client_test.gd`, `skirmish_test.gd` and `skirmish_save_client_test.gd` pass. The client test uses isolated settings files and exercises silence at mute/zero volume plus restored playback.
- `tests/game-audio.test.mjs` validates source, rights entry, hash and WAV format for ten original cues. `node scripts/generate-game-audio.mjs` reproduces them.
- Local native debug captures: [objective at 1280×800](../screenshots/audio-identity/objective-1280.png), [settings at 1024×700](../screenshots/audio-identity/settings-1024.png), [settings at 1280×800](../screenshots/audio-identity/settings-1280.png). The brief center marker sits inside the board tile while text and objective widget remain legible. The added setting is visible and the menu remains scrollable.
- Crowded center captures at [100% UI scale](../screenshots/audio-identity/crowded-100.png) and [125% UI scale](../screenshots/audio-identity/crowded-125.png), both 1280×800: status text, objective widget and units remain visible; the brief ring is less distinct under overlapping units at 125%, so the persistent text carries the state.
- Dense native render probe: 600 frames / 80 units, p95 32.859 ms, peak static memory 43.624 MiB; the untouched master comparison was 32.778 ms and 43.444 MiB. Both are within 33.3 ms and 512 MiB. Single-run hardware measurements are directional.

## Signed downloaded-build checks still owed

Record the exact source commit, export build ID, ZIP and app hashes, signature result, Butler build number, owner download method and test-tagged ingest receipt. Use the existing Restricted owner channel; no invitation or public release. On the downloaded app:

1. Start a solo match, make a valid Gather order and an unaffordable/blocked order. Record what plays and what the on-board text/ring says.
2. Gather/deliver, finish a building, take friendly damage, lose a fighter, and hold/contest the center. Verify priority, absence of repeated noise and no cue from a hidden tile.
3. Mute, set volume to zero, then turn on reduced effects. Repeat representative orders, threat, objective and result; name each state without relying on sound, motion or color alone.
4. Finish once by command-post destruction and once by uncontested center hold; inspect victory, loss and draw with debug fixtures if needed. Save/resume and seek a replay across a prior result. Check one terminal cue in live play, none on seek/reopen, and no duplicate completion event.
5. Confirm the downloaded build's audio preferences persist after quit/reopen and that the current Restricted admission/telemetry settings remain as expected.

## Owner and two uncoached reviewers

Use the same signed build at ordinary viewing distance. Do not explain cue meanings first. Give each reviewer these tasks in sound-on and muted order, balancing the order between reviewers:

1. Issue one accepted and one rejected order. State which took effect and why.
2. Watch gathering, delivery and construction. State which event needs attention and which is routine.
3. Watch a friendly hit and a center contest. Identify the threatened unit and objective state without naming an unseen enemy.
4. Finish a match and state the result cause and next action. Repeat with reduced effects.

For each task record reviewer, sound condition, window/zoom, build ID, recognition correct/incorrect, missed or masked cue, hesitation, cultural confusion and severity. The owner records acceptance or a concrete fix for severe failures. A builder capture or automated assertion is not a human pass.
