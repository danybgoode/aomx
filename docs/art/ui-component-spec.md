# Playable skirmish interface

The [approved HUD reference](approved-hud-concept.jpg) guides the visual hierarchy. The [local capture review](../interface-review/qa.md) records the current Godot implementation. Concept art is visual direction only; the versioned simulation is the source of game rules.

## Runtime components

| Component | Source | Responsibility |
| --- | --- | --- |
| BattleHud | `game/ui/battle_hud.gd` | Resources, age, population, selection, legal commands, queue, objective, minimap, notices, settings and result. |
| CommandButton | `game/ui/command_button.gd` | Drawn icon, readable caption, focus, disabled and targeting states. |
| MinimapPanel | `game/ui/minimap_panel.gd` | Same explored/visible policy as the battlefield; camera navigation. |
| HudSkin | `game/ui/hud_skin.gd` | Shared colors, contrast, and minimum button targets. |
| SkirmishMain | `game/skirmish_main.gd` | Setup, save/replay/private entry, input translation, simulation state projection and persistent display preferences. |

The top bar names **Comida, Materiales, Varos and Terrenos** in full, then shows age, population, timer and pause/reset/settings. The bottom bar shows the selected actor, health/activity, contextual orders and production/research context. The simulation still decides whether an order is legal. Status text and target prompts supplement icon and color states. The result panel names the result and its cause, with a new-match action.

Current playable rules include four resources, four ages, unit counters, three authored maps, fog of war, an AI rival, research, save/replay and command-post or center-hold victory. The minimap cannot reveal an enemy the battlefield hides. There is no public multiplayer mode, campaign, diplomacy or free-form generated map control in this interface.

## Layout and input

At the target desktop windows, 100% critical HUD labels use at least 18 Godot font-size units, secondary labels at least 16, and buttons use at least 44 logical pixels on each axis. The narrow touch prototype uses 16-unit resource labels to keep all four names visible. The HUD grows with larger desktop windows. The player can choose 100%, 125%, 150% or 200% in setup or match settings. At 200% the HUD's footprint is capped at 150% while text gets the remaining increase, preserving space for board picking. On narrow logical canvases, resources move to a second top row, selection and commands stack, commands scroll horizontally, and context opens with **Options**. Choice lists and context cards scroll when their content exceeds the panel. Settings include reduced unit motion. Preferences live in `user://ui-settings.v1.json` and do not change the match save schema.

Keyboard shortcuts, board right-click, minimap clicks and visible buttons share the existing semantic command path. Escape cancels targeting. Focus styling, explicit selected-actor text, health numbers, disabled reasons, text order cues and outcome copy carry status without depending on color or audio alone. Hover tooltips add detail but do not carry the only explanation of an action.

## Touch layout contract

Touch taps use Godot mouse-from-touch emulation and the same select/command adapter. A single tap selects, a tap on a visible command enters its target mode, a tap on the board applies that mode, and **Cancel** leaves it. The horizontal command strip and context drawer must be swipeable without issuing a board order. Two-finger pan/zoom and native-device performance remain in the cross-platform epic; this document does not certify a device. The owner will check target size, scroll discoverability and accidental board orders on a real touch device before calling that surface done.

The original icon shapes and panel decoration are Godot drawing and style resources. Unit portraits reuse project sprites; the reference JPG is not a runtime texture.
