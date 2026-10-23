# Interface builder review and owner QA

**State:** Local builder checks complete for the current interface code. Signed downloaded-build, owner and two uncoached reads remain owed. No public cohort or observed completion baseline exists.

The full preview export gate passed for source commit `04c443da8993`. It produced signed `preview-04c443da8993` (`godot-4.7.2-skirmish-5` / `la-roma-world-5`), source ZIP SHA-256 `c0d6c2dd6a32023069bd6562f82c8d1228d9327ca87fc79917be2f62d69a7f4b`. The local extracted app passed strict signature verification and a bounded headless startup. Butler upload #2190017 targets the existing Restricted `mac-private-alpha` channel; channel processing and independent fetch must be checked before owner download QA.

## Evidence and limits

- Godot 4.7.2 graphical captures were made from `game/tests/hud_capture.gd` at 1024×700 and 1280×800. The capture script supports `HUD_CAPTURE_SCALE=1|1.5|2` and setup, worker, building, settings, reset and result modes. Representative captures are linked below; they are local debug images, not owner-signed binaries.
- `game/tests/skirmish_client_test.gd` passes with result cause, text scale, board/minimap separation, control target, selection, save/replay and one-terminal-event checks. Existing simulation and fog checks remain separate.
- The 200% option increases text to 200% and caps the HUD footprint at 150% on constrained windows. At 1024×700 this leaves a visible and pickable board region; secondary content is available through **Options** and horizontal command scrolling.
- Actual human reading distance, misclick rate, keyboard-only traversal, Restricted admission and signed-download behavior are still unmeasured.

## Rendered examples

| State | Capture |
| --- | --- |
| Setup, 1024×700, 100% | [setup-1024-100.png](setup-1024-100.png) |
| Worker HUD, 1024×700, 100/150/200% | [100%](worker-1024-100.png) · [150%](worker-1024-150.png) · [200%](worker-1024-200.png) |
| Worker HUD, 1280×800, 100/150/200% | [100%](worker-1280-100.png) · [150%](worker-1280-150.png) · [200%](worker-1280-200.png) |
| Worker HUD, 1920×1080, 100% | [large desktop](worker-1920-100.png) |
| Worker HUD, 390×844, 100% | [narrow touch-layout prototype](worker-390-100.png) |
| Result, 1024×700, 100% | [result-1024-100.png](result-1024-100.png) |

## Ten-heuristic inspection

| Heuristic | Builder finding / current resolution | Owner check |
| --- | --- | --- |
| System status | Selection, health, resources, timer, hold, queue, notices and result are textual. | Read each without hovering. |
| Match to world | Full resource names and plain outcome cause replace single-letter stockpiles. | Read without knowing Mexican references. |
| User control | Cancel targeting, reset confirmation, pause/resume, new match and save/replay paths exist. | Recover from a mistaken action. |
| Consistency | Buttons, shortcuts and board input issue the same semantic commands. | Compare one order by mouse and shortcut. |
| Error prevention | Disabled controls and command reasons come from current state; the simulation validates orders. | Attempt an unaffordable build and invalid placement. |
| Recognition | Visible captions and setup field labels reduce reliance on memorized keys. | Start a match without instructions. |
| Flexibility | Shortcuts remain; scalable text and scrolling support different windows. | Use 100%, 150%, 200% and keyboard. |
| Minimal design | Secondary context is collapsible at high scale; the board remains exposed. | Check for crowded or hidden essentials. |
| Error recovery | Save/replay and join failures report causes in existing paths. | Try a missing save/bad replay/admission-off join. |
| Help | Tooltips, order prompts, settings support ID and event log remain available. | Find help without a developer. |

The targets here use [NN/g's ten heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) and [WCAG 2.2](https://www.w3.org/TR/wcag/) as references for inspection. This native Godot game makes no WCAG conformance claim. Static palette pairs in `hud_skin.gd`, calculated with the WCAG relative-luminance formula, are:

| Pair | Ratio |
| --- | ---: |
| Main text / panel | 12.11:1 |
| Muted text / panel | 7.34:1 |
| Gold text / dark panel | 11.54:1 |
| Disabled text / disabled button | 7.78:1 |
| Green health fill / panel | 6.51:1 |
| Gold focus border / button | 7.91:1 |

These are code-color ratios, not a measurement of the rendered pixels or a substitute for owner visual judgment.

## Owner and two fresh reviewers

Use the signed Restricted download on the owner Mac. Record the build ID, window size, interface size, viewing distance, player and any assistive setup. Give the player the tasks below without pointing at controls. Record pass/fail, hesitation, unreadable words, missed targets and recovery for each task, with a screenshot or short clip for a severe issue.

1. Choose a faction, battlefield and difficulty; start a solo match. Explain both victory routes.
2. Read all four stockpiles, age, population, center state and timer. Select one worker, then a group; identify who will act.
3. Gather, build, cancel targeting, then try an unavailable order. Explain the reason and whether the order was accepted.
4. Find production or research progress, pan with the minimap and confirm that unseen enemies remain hidden.
5. Change interface size to 150% and 200%; repeat selection and one order at 1024×700 and 1280×800. Use keyboard focus and reduced motion.
6. Save, return to setup, resume, open a replay, and inspect private join with admission off and on when a test invitation exists.
7. Finish by command-post destruction and center hold; also inspect loss/draw. State the cause and start a new match.

**Decision record:** owner accepts readability and the ten-heuristic findings, or lists severity and a concrete fix. Keep this epic `in-progress` and owner QA open until signed-build and uncoached evidence is recorded. A merged PR alone is not a shipped game feature.
