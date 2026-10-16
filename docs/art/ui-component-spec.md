# UI component specification — current desktop HUD and later controls

## Implemented today

The skirmish creates a CanvasLayer in `game/skirmish_main.gd` with three desktop panels: match status, selection and contextual orders. Buttons use the existing validated `issue()` route, while board right click and keyboard commands remain available. A target prompt and cancel action cover move, gather, build and attack. The status panel reads real match and outbox state; the selection panel uses existing art and actor data. The board draws selection rings, numeric HP, placement preview and order feedback. The faction panel, invite-code LineEdit and support Button remain separate. There is no minimap, multi-selection, camera pan or touch command system. The 1280×800 viewport uses `canvas_items` stretch and was also checked locally at 1024×700.

The approved concept JPG is a visual direction, not a feature inventory. Its food/wood/stone, population, ages, multiple selection, building cards, minimap and mobile controls are not implemented in the current simulation. The current match has one gold stockpile, one source per side, command/recruitment posts, worker/melee/ranged and two win routes.

## Reusable Godot Control boundary

The desktop panels read state and send commands through the existing simulation; a later touch layout can reuse the same command route:

| Component | Reads | Responsibility |
| --- | --- | --- |
| MatchStatus | current match and outbox summary | Faction, build channel, clock, result, sync and restart. |
| ResourceCounter | stockpile and source amount | One current gold resource; future resources require rules/data first. |
| SelectionPanel | selected entity ID and HP | Role, ownership, health, queue/progress. |
| CommandPanel | selected kind and legal actions | Move, gather, build, train, attack; disabled states explain cost or invalid target. |
| DistrictStatus | district_state and progress | Neutral, hold, contested, reset and warning with text plus shape. |
| AlertStack | simulation feedback and order response | Short confirmations/errors without covering units. |
| Minimap | future camera and map viewport | Defer until camera pan/viewport exists; current whole board is visible. |
| TouchCommands | same command adapter | Defer until touch input semantics and target device are defined. |

Use anchors/containers for layout, focus states for keyboard access and usable tap targets for touch. Keep world pixel sprites separate from UI typography and scalable panels. Dark charcoal/stone panels, bronze trim and warm light type can express the concept without flattening the entire HUD into a bitmap. Selection and warning must remain understandable without blue/red alone.

The HUD implementation belongs to the separate readable-battlefield-hud epic. The art pack provides the selection portraits and battlefield sprites.
