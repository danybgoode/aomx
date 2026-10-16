# Sprite and animation specification v0.1

## Coordinate convention

The current simulation stores no facing, fractional movement, animation phase or death duration. The visual layer may remember each entity's previous tile, infer screen-left/screen-right facing from movement, and advance a local presentation clock. No visual frame may alter a simulation tick or command result.

Current exports are static key poses:

- unit_worker_blue/red, unit_melee_blue/red, unit_ranged_blue/red: one 40×56 RGBA pose each, foot pivot (20,55).
- building_command_post_blue/red: one 96×80 pose each, south-footprint pivot (48,79).
- building_barracks_blue/red: one 96×60 pose each, south-footprint pivot (48,59).

The direction label for these first poses is SE in screen space. A horizontal mirror may face SW as a temporary presentation rule. NE/NW poses require original frames before four-direction animation is claimed. Do not invent rotation of a pixel sprite: it changes its projection.

## View-only state cues

- Idle: key pose, no simulation change.
- Move: remember the last tile and facing; a 1–2 pixel visual step or bob may play on a short presentation clock after an integer tile change. The tile center is still authoritative for selection.
- Attack: brief overlay flash or 1–2 pixel pose shift when an existing attack job/cooldown changes. This is feedback, not a new hit time.
- Gather/build: worker pose with a small tool flash or pose shift while existing job is gather/build.
- Construction: reduce saturation and overlay progress from existing complete/progress fields; completion switches to normal art on the original tick.
- Damage: HP bar and color-neutral crack/flash cue from existing HP. Do not hide the health value.
- Death/destruction: remove a unit or barracks when the simulation removes it. A short view-only dust effect may persist at the last ground point; a command post at zero HP can show a darkened terminal sprite. Neither delays outcome.

Recommended presentation timing is 6–8 frames per second for future true walk frames, 4–6 for attack and 4 for gather. These are recommendations, not frame data in v0.1. When true sheets arrive, name frames kind_faction_direction_state_00.png and use identical canvas/pivot across every frame of one kind. Keep animation metadata in the manifest; do not infer it from filename order.

Selection rings and health bars are procedural CanvasItem overlays drawn after world sprites. They are not baked into animated canvases. Friendly/enemy distinction uses silhouette and labels in addition to blue/red color.
