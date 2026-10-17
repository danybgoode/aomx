# Playable skirmish HUD

The approved [HUD reference](approved-hud-concept.jpg) sets the visual hierarchy: a compact global bar, an uncluttered battlefield, and a contextual command bar. The [capture set](../screenshots/readable-hud/README.md) records the actual Godot implementation at four viewport sizes. The concept's extra resources, population, ages, formations, research, and buildings are future design ideas; they are not part of the current simulation.

## Runtime components

| Component | Source | Real data and behavior |
| --- | --- | --- |
| BattleHud | `game/ui/battle_hud.gd` | Responsive top bar, selection, command grid, context cards, objective widget, notifications, and hidden diagnostics. |
| CommandButton | `game/ui/command_button.gd` | Original vector icons, label, keyboard focus, hover, pressed, disabled and targeting states. |
| MinimapPanel | `game/ui/minimap_panel.gd` | Reuses the battlefield terrain classifier and `Skirmish` entities, sources and district; click emits a camera destination. |
| HudSkin | `game/ui/hud_skin.gd` | Shared charcoal, bronze, gold and faction neutral control styling. |
| SkirmishMain | `game/skirmish_main.gd` | Translates player input into the existing `sim.issue()` route, and projects simulation and outbox state into the HUD. |

The top bar currently shows **gold**, faction, match time, pause, a confirmed same-faction Reset action and the support menu. The bottom bar shows the selected sprite, health, real stats/activity, available icon commands, building or recruitment card, and the supported production queue. Shift-click or drag selects a group; its portrait grid can select one member. The secondary mobile drawer exposes the same contextual options. A collapsible objective widget shows district state and hold progress. Notifications keep recent events in the support menu's event log. The minimap pans the existing board camera; there is no separate map simulation.

Command metadata defines display names, icon roles, shortcuts and tooltips in one place. The availability projection checks the current selected actors, gold and production state. The simulation validates the final order. Board right-click, shortcuts and UI buttons share that command path. Build placement has a live valid/invalid preview and Escape cancels targeting.

The current playable rules have one gold stockpile, worker/melee/ranged units, a command post, a recruitment post, and two victory routes. Population, ages, food/materials/terrains, fog of war, research, stop, patrol, repair, guard and garrison are absent from the rules and must not appear as working HUD controls. Defense is also not a simulation stat. The minimap shows the same enemy actors already visible on the battlefield; a future fog implementation must filter both views together.

## Input and layouts

Desktop keeps the selection, commands and context regions persistent, with a minimap at the upper right. Resizing a desktop window scales both battlefield and HUD to the available viewport; the HUD uses one bounded canvas scale for its real controls, while mobile keeps its separate compact layout. Wheel/key board zoom is preserved across later resizes and **0** fits the current window. At 844×390 the bottom bar retains 58 pixel command targets and a compact selection panel. At 390×844 it stacks selection and commands and opens context through **Options**. Objectives collapse on mobile. Godot mouse-from-touch emulation is enabled so touch taps use the same board and command handlers. Hover tooltips are supplemental: disabled building cost or reason is also printed in the context panel. Selection, command activation, cancellation, minimap clicks, pause, reset confirmation, diagnostics, resize zoom and bounds are covered by the client test.

The icon shapes and panel decoration are original Godot drawing and style resources, with no imported icon pack. Selection and building portraits reuse the existing project sprites. The reference JPG is an internal, user-provided visual direction and is never shipped as a runtime texture.
