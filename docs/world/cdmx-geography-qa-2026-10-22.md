# CDMX geography and La Roma QA · 2026-10-22

## Build and content identity

- Candidate: `feat/establish-cdmx-geography-and-maps-s3` stack, before merge.
- Simulation: `godot-4.7.2-skirmish-5`; La Roma content: `la-roma-world-5`.
- `game/content/skirmish.v1.json` and the 28×28 authored grid are unchanged. `cdmx.v1.json` is a presentation and source-reference sidecar, not part of deterministic state or the save/replay content hash.

## Builder verification

| Check | Result |
| --- | --- |
| Official source and rights review | INEGI's 16 AGEM codes/names and the city Cibeles listing checked; no external geometry, coordinates, imagery or page text imported. Exact resource terms remain a gate for any future polygon import. See [source record](cdmx-geography-source-review.md). |
| Registry and map contract | `geography_test.gd` passed: 16 stable IDs, place parents, invalid references and conflicting tile roles rejected. Both starts reach four resource types and Cibeles on comparable routes. |
| Existing map/rules behavior | `rules_content_test.gd` and `world_expansion_test.gd` passed: all three maps, four factions, three AI levels and both terminal routes. The existing simulation owns passability, AI, fog and selection. |
| Save and replay | `skirmish_persistence_test.gd`, `skirmish_replay_test.gd`, `multiplayer_replay_test.gd` and `cross_platform_hash_test.gd` passed. Existing schema-5 state hashes remain unchanged; incompatible versions reject without deleting the source file. |
| Client and rendered setup | `skirmish_client_test.gd` passed, including Roma copy and a generic other-map objective. Godot 4.7.2 rendered [1280×800 and 800×600 captures](../screenshots/cdmx-geography/README.md), inspected for legibility. |
| Contract gate | `npm run skirmish:contract` passed with `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. |

## Open owner and human QA

- Download the exact new Restricted build on the owner Mac, verify its build ID and signature, play full matches ending by command-post destruction and Cibeles hold, then save/resume and replay. The local automated terminal checks do not substitute for this playthrough.
- Review the visible place portrayal. After a separate invitation approval, ask familiar and unfamiliar readers to locate Cibeles, distinguish the real place from the stylized arena and explain both wins without coaching. Record each answer and confusion.
- Until those checks are recorded, keep epic `status: in-progress`; no observed cohort or North Star result exists.

## Release record

Pending merge and Restricted owner build. Fill in the master commit, build ID, archive SHA-256, Butler channel/build number, authenticated fetch and anonymous access result after release. A merge, local export or upload alone does not pass owner QA.
