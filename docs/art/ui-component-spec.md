# UI component specification — later HUD milestone

## Implemented today

The skirmish creates a CanvasLayer in game/skirmish_main.gd with a Label for match/HUD text and a Label for keyboard instructions. A PanelContainer, two faction Buttons, invite-code LineEdit and support Button are created in code. The board itself draws selection rings, numeric HP, placement preview and order feedback. There is no minimap, multi-selection, contextual command panel, camera pan, touch command system or responsive layout. The 1280×800 viewport uses canvas_items stretch.

The approved concept JPG is a visual direction, not a feature inventory. Its food/wood/stone, population, ages, multiple selection, building cards, minimap and mobile controls are not implemented in the current simulation. The current match has one gold stockpile, one source per side, command/recruitment posts, worker/melee/ranged and two win routes.

## Reusable Godot Control plan

A later desktop/touch HUD should use one shared command adapter that sends existing validated issue() intents, then separate responsive Control layouts:

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

No HUD implementation is in the v0.1 art epic beyond maintaining the current information and procedural feedback.
