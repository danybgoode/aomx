# La Roma battlefield art v0.1 — technical QA record

Date: 2026-10-16. Host: Apple M2 Max, Godot 4.7.2 GL Compatibility, local debug scene at 1280×800. This is internal test traffic, not a public play cohort.

## Observed in the rendered game

| Check | Observation |
| --- | --- |
| Faction choice | Poblanos show blue command post/worker against red Regios; choosing Regios reverses the ownership colors without changing player side or match rules. |
| Map at 100–125% | Four authored terrain classes, both carts, fixed barricade line, two jacarandas and plaza medallion align to the original board. The center is recognizable in neutral and contested states. |
| Depth and transparency | HQs, worker and center fighters display transparent edges. Ground-depth sorting puts units at the center in front of the plaza and behind nearer sprites. No obvious opaque atlas cells were seen. |
| Prop priority | A fresh local verifier confirmed tall props draw before actors. This is deliberate: a walking or selected unit must remain visible even when crossing the decorative jacaranda or an edge of a cart/barricade. It can look physically in front of a foreground prop; v0.1 favors readable and tile-selectable units. |
| Selection and commands | In the crowded `district_contest` fixture at 125%, clicking the blue fighter's ground tile selected ranged #5; right-clicking the red fighter's ground tile yielded “Attacking target.” Clicking the upper part of an overhanging sprite hit a different tile and yielded “Moving here.” Instructions now explicitly direct clicks to unit feet. This is the existing tile-picking rule. |
| Match result | An unattended Poblanos debug match reached a district loss and displayed the terminal result. In the `district_contest` fixture the blue fighter attacked the red fighter, the center changed from contested to friendly hold, and at 01:23 the scene displayed “Result: win” and “La Roma held. Victory!” with one saved result. |
| Construction and damage | The AI produced a red barracks in the local match, and health bars reflected reduced command-post HP. The existing construction/placement tests passed; a hands-on visual construction walkthrough is still required. |
| Zoom | A 100% pilot and 125% crowded center were inspected. Tile anchors stayed aligned. Fractional zoom softens some pixel clusters, especially the small unit details. |

The visual source and 30 exported RGBA PNGs are retained in `game/assets/`. `scripts/export-art.sh` produces byte-identical exports on successive runs; `node scripts/validate-art-manifest.mjs` verifies IDs, paths, dimensions and RGBA format. No downloaded reference pixels or audio entered the build.

The signed art preview `preview-9e1c6f0e3a3e` is live on the Restricted itch.io `mac-private-alpha` channel as build `#2139865` (`dist/alpha/battle-for-la-roma-preview-9e1c6f0e3a3e-macos.zip`, source SHA-256 `84b4aa9aa31653144fad7541c527e14af6dfcd83735a7f0f6f590dfb84e9c5f3`). ZIP integrity and strict code-signature verification passed; the extracted packaged app launched for 20 headless frames. Butler fetched the processed build back to this Mac: the app files matched the signed local candidate byte for byte, its strict signature verified and it started. The earlier packaged candidate opened with the new battlefield sprites, faction setup and private alpha invite controls in a rendered local check. An owner browser download and full playthrough are still separate checks.

Three targeted Antigravity cross-family PR reviews covered the art pipeline, renderer and QA changes. Their actionable findings were fixed: board X bounds, catalog reload, building overlay anchors, stationary attack facing, bobbing cues and an overwritten instruction. The renderer review also questioned props drawing below actors; the v0.1 readability choice is recorded in the pipeline spec and above. The reviews were scoped to text files because the PNG diff exceeded the review input budget; they are not a review of every source atlas pixel.

## Automated checks

- `npm test`: 15 passed, 1 skipped (Postgres integration fixture unavailable); the initial sandbox-only loopback `EPERM` was resolved by rerunning with normal local network permission.
- Godot headless: simulation, outbox, skirmish, faction, district and skirmish-client checks passed.
- `npm run skirmish:contract`: one test-tagged start/result, stable retry and zero public events passed.
- Godot simulation benchmark: 20×20/12 units, 5,000 routes mean 0.4525 ms, 1,000 ticks mean 0.0423 ms. This measures the unchanged simulation, not sprite rendering.
- Rendered debug art probe (`game/tests/art_render_probe.gd`, 180 displayed frames, 20×20/12 units): 100% zoom frame interval median 8.27 ms, p95 13.81 ms; 125% zoom median 8.33 ms, p95 14.21 ms. Godot process monitor showed ~14.7 ms and peak static memory 32.6 MiB. Intervals include display wait. The older 14–28 ms baseline in `game/README.md` was a different debug observation, so it is not a controlled before/after comparison. No mobile, WebGL or hundreds-of-units claim follows from these measurements.

## Owner QA follow-up — selection and scale

After several owner matches, clicking overhanging unit bodies and the visible gold cart remained difficult because the input only rounded to the ground tile. The 40×56 unit exports also appeared almost as tall as 96×60 recruitment posts. The view now shows units at 75% (30×42 visual canvas) and checks cached sprite alpha with a small tolerance before falling back to ground-tile selection. Hover outlines and a short action hint show friendly selections, gold gathering and enemy attack targets; the active unit has a cyan outline, foreground ground ring and arrow. These remain view-only, with the same entity IDs and source tiles sent through simulation validation.

The Godot client check clicks above the worker's ground tile to select its visible body and above the source tile to order gathering from the cart body. Both passed. Rendered GL Compatibility captures at 110% showed readable smaller units, a visible active marker and a hover hint clear of the HUD. With the same 20×20/12-unit, 180-frame probe after this change, 100% zoom measured median 8.15 ms/p95 12.23 ms and 125% measured median 8.30 ms/p95 11.85 ms; peak static memory was 33.3 MiB. These displayed-frame intervals include wait time and are not a controlled performance comparison. The owner should retest selection and scale in the next downloadable preview.

The signed selection-and-scale source ZIP for `preview-6d6016d42d8e` was uploaded to the same Restricted itch channel as build `#2140875`. As of the last 2026-10-16 Butler status check, itch still reports it processing and `preview-9e1c6f0e3a3e` remains the ready download. Local signed-export checks passed, but remote fetch, packaged signature and owner browser download checks on the new build remain open until processing finishes. The owner retest steps are in `docs/alpha-local-qa.md`.

## Remaining outcome and release checks

- One culturally familiar and one unfamiliar blind reviewer must identify the two win routes and friend/enemy roles without coaching. Record their exact answers here before the epic is marked shipped.
- Complete a hands-on construction/placement, Regios full-match and offline restart/sync walkthrough on the final downloadable preview; the deterministic client/outbox checks do not substitute for owner-Mac download QA.
- The art preview is live on the Restricted itch channel. It is not an invitation; owner browser download QA and the existing invitation gates remain separate.
