#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/game/assets/source/owned"
OUTPUT="$ROOT/game/assets/render/owned"
mkdir -p "$OUTPUT"
command -v magick >/dev/null || { echo "ImageMagick is required" >&2; exit 1; }
# The 32x16 top diamond becomes 48x24. These raised tiles are pilot-only.
for tile in 000 022; do
  magick "$SOURCE/tile_${tile}.png" -filter point -resize '48x48!' -strip "PNG32:$OUTPUT/tile_${tile}.png"
done
# Native-size flowers are a view-only prop, never a blocking tile.
magick "$SOURCE/tile_044.png" -strip "PNG32:$OUTPUT/tile_044.png"
# Retain the original 46x32 frames and their lower-center feet anchor.
for direction in NE NW SE SW; do
  for frame in 0 1 2 3 4 5 6; do
    magick "$SOURCE/boar_${direction}_idle_${frame}.png" -strip "PNG32:$OUTPUT/boar_${direction}_idle_${frame}.png"
  done
done
# Generated transparent concept derivative; narrow to the established 2x2 silhouette.
magick "$SOURCE/concept_command_post_blue.png" -filter Lanczos -resize '96x85!' -strip "PNG32:$OUTPUT/concept_command_post_blue.png"
echo "Exported 32 owned-art candidates"
