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

The final signed candidate is `preview-9e1c6f0e3a3e` (`dist/alpha/battle-for-la-roma-preview-9e1c6f0e3a3e-macos.zip`, SHA-256 `84b4aa9aa31653144fad7541c527e14af6dfcd83735a7f0f6f590dfb84e9c5f3`). ZIP integrity and strict code-signature verification passed; the extracted packaged app launched for 20 headless frames. The earlier packaged candidate opened with the new battlefield sprites, faction setup and private alpha invite controls in a rendered local check. A downloaded-from-itch owner playthrough is still a separate check.

Three targeted Antigravity cross-family PR reviews covered the art pipeline, renderer and QA changes. Their actionable findings were fixed: board X bounds, catalog reload, building overlay anchors, stationary attack facing, bobbing cues and an overwritten instruction. The renderer review also questioned props drawing below actors; the v0.1 readability choice is recorded in the pipeline spec and above. The reviews were scoped to text files because the PNG diff exceeded the review input budget; they are not a review of every source atlas pixel.

## Automated checks

- `npm test`: 15 passed, 1 skipped (Postgres integration fixture unavailable); the initial sandbox-only loopback `EPERM` was resolved by rerunning with normal local network permission.
- Godot headless: simulation, outbox, skirmish, faction, district and skirmish-client checks passed.
- `npm run skirmish:contract`: one test-tagged start/result, stable retry and zero public events passed.
- Godot simulation benchmark: 20×20/12 units, 5,000 routes mean 0.4525 ms, 1,000 ticks mean 0.0423 ms. This measures the unchanged simulation, not sprite rendering.
- Rendered debug art probe (`game/tests/art_render_probe.gd`, 180 displayed frames, 20×20/12 units): 100% zoom frame interval median 8.27 ms, p95 13.81 ms; 125% zoom median 8.33 ms, p95 14.21 ms. Godot process monitor showed ~14.7 ms and peak static memory 32.6 MiB. Intervals include display wait. The older 14–28 ms baseline in `game/README.md` was a different debug observation, so it is not a controlled before/after comparison. No mobile, WebGL or hundreds-of-units claim follows from these measurements.

## Remaining outcome and release checks

- One culturally familiar and one unfamiliar blind reviewer must identify the two win routes and friend/enemy roles without coaching. Record their exact answers here before the epic is marked shipped.
- Complete a hands-on construction/placement, Regios full-match and offline restart/sync walkthrough on the final downloadable preview; the deterministic client/outbox checks do not substitute for owner-Mac download QA.
- The existing Restricted itch preview and invitation gates are separate. This source branch and local debug scene are not a deployed build or an invitation.
