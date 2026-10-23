# Owner review: interface scale, battlefield cues, movement and map space

**Date:** 2026-10-23
**Evidence:** owner screenshot at `references/regios-command-post.png`, Restricted preview `preview-222748c6be7a`, interface size 200%, Regios command-post win at 04:16; owner report of units blocking each other and tightly grouped resources. The screenshot is a local owner reference, not a checked-in build artifact.
**Disposition:** open findings. This note records a proposed design and acceptance plan; it does not mark any epic shipped or change the approved map/content rules.

## What the owner is asking for

The presently labeled **200%** interface is the first size the owner finds comfortable. It should become the perceptual **100% default**, with panels and controls redesigned to fit the text. The battlefield should show fewer competing marks around units. Workers and other units should recover from crowding. The playable map and resource journeys should feel materially larger and less compressed, using Age of Empires II: Definitive Edition's **Large** map experience as a reference for exploration and expansion rather than copying its tile count.

## Findings and ownership

| Finding | Evidence and likely mechanism | Existing owner |
| --- | --- | --- |
| Text and controls overflow at the only comfortable scale | The screenshot shows the objectives body clipped; the settings title, close control, explanatory copy and slider crowd each other; and selection, command captions and context copy spill from the bottom HUD. `battle_hud.gd` caps panel scale at 1.5 while boosting font size beyond that, then gives objectives, dialogs and bottom columns fixed logical dimensions. The local 1024×700/1280×800 builder captures do not override this owner result. | [#18 Complete game interfaces](../../02-civilizations-and-world/complete-game-interfaces/README.md), open S3.3 and owner DoD. |
| Too many persistent unit indicators | Current rendering draws health bars for every visible entity, faction glyphs on La Roma, permanent armor/siege badges, selected rings plus outlines, hover rings plus outlines, and transient order marks. The combined density is the finding; a health-bar toggle alone would leave competing marks. | #18, with the earlier [HUD owner finding](../../02-civilizations-and-world/readable-battlefield-hud/README.md) remaining transferred there. |
| Units can remain blocked and appear abandoned | Current occupied-tile handling waits; `_reroute_occupied()` reports crowding but does not calculate an alternate occupied-aware route. At a later threshold the path is cleared and the job becomes idle. This is a code-level plausible mechanism, not yet a reproduction of the owner's exact match. | [#11 Expand warfare and world](../../01-core-play/expand-warfare-and-world/README.md), open S1.2 and non-stuck DoD. |
| The board and resource journeys feel small | The playable base map is 28×28 for La Roma, Narvarte and Copilco. The 48×48/163-entity case is a headless benchmark only. #11 promised a larger battlefield, but its architecture lock accepted 28×28/80 units; #16 preserves the 28×28 La Roma geography contract. Resources are authored near starts and central approaches. Camera zoom can enlarge sprites, but cannot add exploration space or resource travel choices. | #11 scope gap, requiring a new architecture/content decision before a playable larger-map claim. |

## Proposed interface contract for #18

1. **Reset the baseline:** on a fresh install, label the comfortable visual size in the owner screenshot as 100%. Preserve accessibility enlargement options through real reflow. Version the stored `user://ui-settings.v1.json` preference and migrate existing saved values so an old 200% preference does not accidentally double in physical size. UI scale and battlefield zoom stay independent.
2. **Design around content:** the status strip may wrap into two rows; resource and population values remain readable. The bottom selection, commands and context areas use available viewport width and measured minimum content sizes. If a window is narrow, switch to a stacked or tabbed arrangement with scrollable secondary content. A dialog sizes and scrolls to its content; its close action stays reachable. No essential text, button or feedback may be clipped, covered, or drawn outside its panel.
3. **Keep the battlefield usable:** reserve a continuous visible play area and preserve selection, panning and minimap use while panels or dialogs are open. Avoid solving overflow by simply shrinking type back to the old 100% size.
4. **Check actual states:** fresh setup; one unit and a selected group; worker gather/build; research/production; busy objective; settings/support; result with simultaneous notice; keyboard focus; reduced motion/effects. Inspect the owner screenshot state at its actual display size, plus 1280×800 and 1024×700, at the new default and each offered enlargement. Record an owner downloaded-build pass and the two uncoached reads already owed by #18.

Proposed desktop composition at the new 100%:

```text
┌ Resources · population · age ─────────────── Time · pause · menu ┐
│ Goals, collapsible                     Fog-aware minimap          │
│                                                                │
│               Readable, pickable battlefield                   │
│                                                                │
├ Selected unit/group ┬ Contextual commands ┬ Queue / current goal ┤
└─────────────────────┴─────────────────────┴──────────────────────┘
```

The three bottom areas share the viewport width instead of keeping narrow fixed columns in the center. Their content determines a minimum height; on smaller windows, secondary context opens as a scrollable tab rather than squeezing essential commands. Settings and result dialogs sit above this layout, wrap their text and retain an always-visible close/continue action.

### Battlefield cue hierarchy for #18

| State | Proposed default battlefield cue | Details elsewhere |
| --- | --- | --- |
| Ordinary, full-health, unselected unit | Sprite and a restrained friend/foe identity cue; no persistent health bar, role badge or order text. | Hover/selection and HUD. |
| Selected unit or group | One clearly legible selection treatment per member; distinguish the primary member in the selection panel, not with multiple stacked outlines. Show health for selected/damaged members when it helps a decision. | Group count, role, current action and exact health in the HUD. |
| Hovered unit | Brief highlight and concise identity/health detail that does not cover nearby units. | Tooltip or selection panel. |
| Combat, recent damage or critical health | Contextual bar or short-lived alert, with priority for threatened units. Use color plus shape/text; avoid a field of full green bars. | Exact value on selection. |
| Order, invalid target or no route | Short-lived destination/target marker and a durable, accessible failure message when the order cannot complete. | Command status and selected-unit state. |
| Building under construction or damaged | Progress/damage cue only while relevant. | Exact state on selection. |

Offer a clearly named **contextual / always** health-bar preference only if the default can stay quiet and both modes pass dense-battle review. Check fog legality before showing enemy health or an off-screen/hidden target. At fit view and enlarged zoom, a player must still identify selected friendlies, a threatened worker, an armored or siege role when selected, and the reason an order failed. Remove a redundant marker when it adds no new decision information.

The reference principle comes from the [official AoE II: DE interface guide](https://www.ageofempires.com/learn-to-play/control-resources-aoe2/), which separates persistent resources from selection-dependent commands and unit statistics, and its [accessibility guide](https://www.ageofempires.com/age-ii-de-accessibility/), which documents configurable HUD scale, readability panels and selection/hover highlights. The cue rules above are our proposed application of those principles, not a claim that AoE II: DE uses these exact health-bar rules.

## Movement recovery contract for #11

Capture a saved/replayable owner case if available, then create deterministic crowded worker and mixed-army cases. Assert what the player observes over enough ticks to pass the current wait/abort thresholds. When a legal alternative route exists, a unit should reroute or otherwise progress without permanent overlap. When no route exists, its order must fail visibly and persist in selected-unit status until the player can act; gathering/delivery should not silently become idle with cargo. Check simultaneous swaps, same-destination groups, production exits, buildings added/removed, save/resume, replay and macOS/Linux state hashes. Re-run the declared route/tick/frame/memory budgets and independent high-risk review before treating the fix as verified.

## Larger-map follow-on plan

The current #11 promise should not be counted as complete on a 28×28 board. **Owner scope choice, 2026-10-23: one larger pilot map first, aiming for the exploratory and expansion feel of an AoE II: DE Large match.** The earlier tentative 48×48 target is too modest to assume that experience: it is about 3× the current tile area. Begin a playable scale study around 96×96 (about 12× the current area), with 128×128 as the present content validator's upper bound (about 21×); choose final dimensions from owner play, route density and performance, not from an unverified AoE tile conversion. Proposed implementation is an authored La Roma large variant with two fair starts, safe early resources, multiple scouting routes, separated expansion resources and meaningful buildable space; retain the current 28×28 map and its save behavior for comparison. The default camera should open at a readable unit size around the player's start, with pan/zoom and the minimap making the unseen map discoverable. A fit-whole-map action can remain available but must not set the default unit scale. Judge the pilot by scouting time, travel/resource risk, viable expansion sites, camera/minimap navigation and complete-match duration, rather than tile count alone. Set a new owner-Mac performance budget before tuning; verify AI, fog, pathing, balance, content versioning, old-save behavior, replay/hash and both win routes in a downloaded build. A 48×48 headless benchmark is useful prior evidence but is not that acceptance.

### Starting scout: bicitaxi

**Owner addition, 2026-10-23:** each side starts the larger pilot with one bicitaxi scout. Mexico City's mobility department describes a bicitaxi/ciclotaxi as [individual passenger transport by bicycle](https://www.semovi.cdmx.gob.mx/storage/app/media/uploaded-files/diagnostico-tecnico-de-movilidad-pim.pdf), mainly serving short neighborhood and first/last-leg trips. Its [street-design reference](https://disenovial.plazapublica.cdmx.gob.mx/assets/files/Consulta%20P%C3%BAblica%20Manual%20de%20Dise%C3%B1o%20Vial.pdf) includes a photographed bicitaxi on Avenida Chapultepec. Use the vehicle as a respectful CDMX-inspired silhouette, without claiming it is the typical transit mode of every neighborhood or assigning real operators fictional combat behavior.

For this pilot, propose a fast, fragile, **non-combat** starting scout with longer sight than a worker, one per side, controlled by the existing move/stop commands and normal fog rules. It should reveal routes and expansion resources but neither gather, build, carry passengers, attack nor replace a military unit. Keep its sprite and one selection cue recognizable at the default camera scale; do not add another permanent battlefield badge. The AI must scout with the same information rules as the player. A bicitaxi stopped by crowds must meet the movement recovery contract above. Exact speed, sight, hit points and cost are balance decisions to pin in versioned content after a playable comparison; any later training or transport ability requires a separate scope decision. Save/replay, hashes, group selection, UI text, art provenance and a full-match smoke cover the new role.

The art brief should read as a bicycle-powered passenger vehicle with a distinct cycle-and-cabin silhouette, in each side's palette, at the real camera scale. The vehicle is a scouting role in this fictional match; its real-world passenger-service purpose belongs in respectful tooltip/context copy, not a caricature.

The precise dimensions and resource layout remain design candidates until measured in a playable pilot. No public release or AoE II: DE numerical parity is implied.

## Suggested order

1. Repair #18 layout at the new readable default and reduce battlefield cue clutter; verify the owner's screenshot states before completing its human QA.
2. Reproduce and repair #11 congestion on the current map. Movement must be trustworthy before travel distances increase.
3. Review the [L-sized large-map and bicitaxi plan](../seeds/build-large-la-roma-battlefield.md). On approval, place it behind the repairs and before campaigns, then prove the full match on the larger board. Resolve #11's older larger-map DoD explicitly at that boundary without counting the same outcome twice.
