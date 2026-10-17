# Readable battlefield HUD captures

Approved [visual direction](../../../references/04a1d5324f0edb9c8e41f5a474ec3f49255671b7baf530e4de7f154e661cce23.jpg) and actual Godot 4.7.2 gameplay captures:

| Viewport | Actual state |
| --- | --- |
| [1536 × 960](desktop-1536x960.png) | Worker selection, health, move/gather/build, construction card, objectives and minimap. |
| [1920 × 1080](desktop-1920x1080.png) | Command post selection, recruitment action and production queue. |
| [844 × 390](mobile-844x390.png) | Landscape touch layout, collapsed objectives, worker command targets and minimap. |
| [390 × 844](mobile-390x844.png) | Portrait layout, board, selection, commands and expandable options. |

The reference shows a mature army and economy; this solo scenario supports one gold resource and fewer commands. The delivered HUD follows its top/field/bottom hierarchy and charcoal/bronze style without presenting the reference's unsupported systems as playable. The desktop panels have some open space when only one to three legal actions exist. The current game art has no dedicated painted portrait set, so entity sprites are used as portraits. The mobile board is navigated through the minimap; gesture pan and pinch zoom are future improvements.

These captures include the proportional desktop HUD scale and visible **Reset** control. Reset opens an in-game confirmation and starts a new match with the same faction; **R** still returns to faction choice.

To reproduce a capture from the repository root, set `HUD_CAPTURE_PATH` to an absolute output path, `HUD_CAPTURE_MODE` to `worker` or `building`, and run Godot with `--path game --rendering-driver opengl3 --resolution WIDTHxHEIGHT --script res://tests/hud_capture.gd`. The script uses an isolated test outbox and disables AI before saving the root viewport image.
