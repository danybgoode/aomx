# Isometric geometry — current skirmish

Status: refreshed from `game/skirmish_main.gd`, map content and rendered #15 captures on 2026-10-22. This describes the current match, not the older worker prototype or concept paintings.

## Coordinates

The current La Roma simulation stores integer Vector2i tiles in a 28×28 grid. Elevated tiles are simulated map attributes, while entity positions remain integral. A move advances a whole tile on a fixed 0.1-second tick; the renderer receives no interpolation fraction. Game paths, wall blocking, resource sources and the central district use these tile coordinates.

The Node2D view converts a tile (x,y) to the center of its screen diamond:

- screen_x = 640 + 24 × (x − y)
- screen_y = 65 + 12 × (x + y)

The visible ground diamond centered there has corners (0,−12), (24,0), (0,12), (−24,0), so its ground footprint is exactly 48×24 screen pixels before zoom. Positive tile X goes down-right; positive tile Y goes down-left. The 28×28 tile centers span x −8–1288 and y 65–713. Including diamond tips, the unzoomed board extrema are x −32–1312 and y 53–725; fit zoom and pan determine the visible portion.

Input first reverses board zoom, then solves the two projection equations and rounds each coordinate to the nearest integer tile. For visible actors and the gold cart, the view checks the cached sprite alpha first and maps a hit to the original entity ID or source tile; exact simulation tile picking remains the fallback. There is no physics collider. A unit occupies one tile. Both command_post and barracks use a 2×2 logical footprint beginning at entity.pos; the union of those four ground diamonds is 96×48 pixels. Its ground center is 12 pixels below the first tile center and its southern tip is 36 pixels below that center.

## Zoom and layers

The board is not a Camera2D. Node2D._draw applies a transform around (640,305) plus pan and responsive offset. The default desktop zoom is 1.1 at 1280×800; controls clamp to 0.7–2.1 and `0` returns to fit. The CanvasLayer HUD is outside this transform. Fractional zoom can unevenly enlarge pixel clusters; judge art at 1.0, 1.25, fit and a crowded center instead of promising pixel-perfect integer scaling.

Current draw order is terrain, district/fog and decorative props; then resource sites; then actors sorted by projected ground Y and stable entity ID; then placement and order feedback. The CDMX Cibeles sprite is an underlay, drawn only after exploration and dimmed outside vision, so it cannot intercept unit picking. Health, faction, selection and order marks are separate state overlays. Selection and collision remain tile based.

## Anchors and canvas

Requirements:

- Terrain export: 48×27 RGBA. The top 24 pixels align to one 48×24 ground diamond; at most three pixels of relief extend below it. Draw origin is tile center minus (24,12).
- Unit export: 40×56 RGBA. Feet/ground anchor is (20,55), placed at the tile center. The view displays units at 75% (30×42 visual canvas) so people read below the 60-pixel barracks and 80-pixel HQ heights. Transparent canvas and artwork overhang do not affect occupancy.
- CDMX building exports: 96×80 RGBA for all five current kinds. Southern footprint tip is anchor (48,79), placed at tile_to_screen(entity.pos) + (0,36). The old barracks export remains 96×60 on other maps.
- CDMX Cibeles export: 96×80 RGBA, anchor (48,79), drawn at the existing district tile (10,10). Its apparent area never changes the district rectangle or pathing.
- Image alpha is genuine transparency; selection and HP overlays remain independent of the image.

The visual hit helper reverses board zoom, applies each sprite's ground anchor and display scale, then checks cached alpha with a four pixel tolerance in the source image. A successful sprite hit resolves to the original entity ID or source tile before issuing a command; the simulation still validates selection and orders.

The [CDMX source record](cdmx-art-source.md) contains the exported asset contract and actual-scale captures. Dense unit badges remain a visual review point for the owner; the current alpha hit test and hover/selection ring still resolve to simulation entity IDs.
