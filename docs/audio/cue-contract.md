# Match audio and effects contract

**Scope:** #19's original native-desktop cue pack. Gameplay, saves, replays, networking and funnel events remain owned by their existing systems. The [epic](../../Roadmap/02-civilizations-and-world/build-audio-and-effects-identity/README.md) is the approved scope; this file is the build contract.

## Style and rights

The palette uses short, dry synthesized tones: a high paired chime for an accepted command, a falling pair for rejection, light upward steps for economy/construction, rough lower pulses for danger, a stronger interval for the center, and related three-note terminal motifs. Those are original game signals, not recordings of a city or stand-ins for any region or people. No joke, place knowledge or language is needed to identify a cue's game role.

`scripts/generate-game-audio.mjs` generates all ten mono 22,050 Hz, 16-bit PCM WAVs without samples or recordings. [The cue manifest](../../game/assets/audio/cues.manifest.json) records each asset's source, project-original rights statement, duration and SHA-256, plus the generator hash. Regenerate with `node scripts/generate-game-audio.mjs`; `node --test tests/game-audio.test.mjs` checks the source and every export. Do not add a third-party asset without a source and commercial-use decision.

## Mapping and priority

The client observes accepted results or visibility-safe state transitions in `game/skirmish_main.gd`. `game/presentation_cues.gd` claims an event key once and enforces category cooldowns. Higher-priority cues can replace a lower-priority playing voice. The pool has at most **three** voices. No cue writes to the simulation.

| Cue | Trigger | Priority / cooldown (ticks) | Non-audio equivalent |
| --- | --- | --- | --- |
| `order-confirm` | Locally accepted order or host acknowledgement | 2 / 0 | Green order ring, text, activity |
| `order-reject` | Local invalid/disabled order or host rejection | 3 / 0 | Red order ring, plain reason |
| `economy` | Friendly worker gathers from empty hands or delivers carried stock | 1 / 35 | Worker activity, stockpile, delivery notice |
| `construction` | Friendly unit ready or building completed | 2 / 12 | Ready/complete notice and building state |
| `threat` | Friendly entity HP drops | 4 / 18 | Attack notice, HP bar, small exclamation |
| `destruction` | Friendly fighter disappears after a live state transition | 4 / 8 | Unit-lost notice; small exclamation only while its old tile remains visible |
| `objective` | Visible center becomes held or contested | 5 / 8 | Objective widget and center notice |
| `result-win/loss/draw` | First terminal transition in a live match | 6 / 0 | Result title, cause and new-match action |

Effects last **0.55 seconds**, occupy a small ring and symbol at a visible tile, and are capped at **five** concurrent markers. Order rings already exist and are not duplicated. Reduced effects removes transient markers but keeps text, health, objective, result and selection cues. Mute or zero volume stops voices; the original `audio-settings.v1.json` keys remain valid. `ui-settings.v1.json` adds `reduced_effects`; older saved `reduced_motion` becomes its initial value until the player chooses separately.

## Visibility and replay

Friendly state and a visible center can make cues. A hidden tile cannot make a positional marker or reveal an enemy through the cue path. An owned fighter's loss remains audible and visible as a non-positional notice after its old tile returns to fog. Threat cues identify the friendly target, never a hidden attacker. Start, resume, first network state and replay seek establish a silent baseline; only later observed transitions emit. Repeated terminal frames share a match result key and cannot replay the result tone. A host acknowledgement is the online order confirmation; a queued request is visibly labelled as awaiting the host with an amber ring.

## Performance and QA

The dense native probe (`game/warfare_render_probe.gd`, 600 frames, 80 units, 1280×800, M2 Max, Godot 4.7.2) has an existing **33.3 ms p95 frame** and **512 MiB static memory** budget. Untouched `origin/master` measured **32.778 ms / 43.444 MiB**; this branch measured **32.859 ms / 43.624 MiB** under the same probe. Both pass, with little frame margin; the 0.081 ms difference is a single-run observation, not a stable effect size or minimum-device claim. Keep the bounded pool and effects caps, and recheck any larger media wave. See [QA and human task sheet](qa.md).
