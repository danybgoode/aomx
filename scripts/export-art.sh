#!/usr/bin/env bash
set -euo pipefail

ART_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../game/assets" && pwd)"
SOURCE="$ART_ROOT/source"
OUTPUT="$ART_ROOT/render"
mkdir -p "$OUTPUT"
command -v magick >/dev/null || { echo "ImageMagick 'magick' is required to export art." >&2; exit 1; }

# Fixed cells and bounds are measured from the retained, transparent source atlases.
# Terrain exports include a 48x24 ground diamond plus up to 3 pixels of edge relief.
terrain_row() {
  local label="$1" source_y="$2" source_h="$3"
  local col offset_x
  for col in 0 1 2 3; do
    offset_x=$((23 + 384 * col))
    magick "$SOURCE/terrain_atlas.png" -crop "339x${source_h}+${offset_x}+${source_y}" +repage \
      -filter Point -resize '48x27!' -channel A -threshold 35% +channel \
      "$OUTPUT/terrain_${label}_${col}.png"
  done
}
terrain_row grass 44 183
terrain_row sidewalk 285 188
terrain_row asphalt 536 186
terrain_row plaza 776 189

building() {
  local id="$1" bounds="$2" height="$3"
  magick "$SOURCE/building_atlas.png" -crop "$bounds" +repage \
    -filter Point -resize "96x${height}!" -channel A -threshold 35% +channel \
    "$OUTPUT/${id}.png"
}
building building_command_post_blue '651x536+86+27' 80
building building_command_post_red '650x536+806+27' 80
building building_barracks_blue '643x395+86+601' 60
building building_barracks_red '642x395+806+601' 60

unit() {
  local id="$1" bounds="$2"
  magick "$SOURCE/unit_atlas.png" -crop "$bounds" +repage \
    -filter Point -resize '36x54!' -background none -gravity south -extent 40x56 \
    -channel A -threshold 35% +channel "$OUTPUT/${id}.png"
}
unit unit_worker_blue '282x426+165+46'
unit unit_melee_blue '275x416+630+56'
unit unit_ranged_blue '289x432+1110+40'
unit unit_worker_red '282x425+165+536'
unit unit_melee_red '275x416+630+546'
unit unit_ranged_red '289x429+1110+534'

echo "Exported terrain, building and unit PNGs to $OUTPUT"
