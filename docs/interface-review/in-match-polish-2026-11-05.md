# In-match polish review · 2026-11-05

## Home screen finding

The public game's current home screen is an adaptation of `battle-for-la-roma-match-setup-lore-v2.html`, but it is not the complete supplied concept. It has the later background, logo, navigation and match setup routes. The illustrated faction cards and more elaborate lore layout in the reference were deferred. This review did not change the home screen; campaign map availability was changed in match setup at the owner's request.

## Owner findings addressed

The owner's `regios-worker-build.png` shows a cramped 100% match layout. The HUD now uses available width and height to size its top and bottom regions, lets commands scroll when needed, and keeps selection details in view. The faction portrait, age art, color-coded resource icons, and labeled action icons replace text-only identification. Resource sites show their stock, refreshes or replant status when selected, and a visible depletion gauge with full, half and empty treatment while in sight. The minimap differentiates resource kinds by color and shape. Selection uses one ground ring instead of stacked sprite silhouettes.

Explored fog retains terrain and static resource silhouettes but hides live enemy state and current site amounts outside vision. A move into an explored blocked tile chooses the nearest walkable tile. A worker changing resource jobs delivers carried cargo first, then resumes gathering the requested resource. Campaign chapters can launch on all five supported solo maps, with their authored map still the default.

## Builder verification

The complete standalone Godot test suite passed, including the new cargo, resource, movement, campaign map and persistence checks. Node tests passed (56 passed, three database tests skipped without a test database). Temporary Web export captures at 1907×931 and 390×844 showed fitted HUD controls and a centered match board. The browser capture exercised local gameplay, not a freshly downloaded public build. Public Web and macOS release verification is recorded separately after publication.

The epic's owner and two uncoached readability tasks remain open. A live two-human match, physical phone pass and measured first-match completion remain open evidence, not assumptions from the local checks.
