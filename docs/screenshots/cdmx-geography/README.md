# CDMX geography setup captures · 2026-10-22

These are actual Godot 4.7.2 renders of the native skirmish setup after the Roma Norte/Cibeles copy change: [1280×800](setup-1280x800.png) and [800×600](setup-800x600.png). Both show the named location, stylized-map note, independent faction choices and a Cibeles hold route. The 800×600 setup scrolls to reach the lower faction choices, as it did before this change.

Capture command from the repository root, substituting the desired size and output path:

```sh
HUD_CAPTURE_MODE=setup HUD_CAPTURE_PATH=/absolute/path/setup.png \
  /Applications/Godot.app/Contents/MacOS/Godot --resolution 1280x800 \
  --path game --script res://tests/hud_capture.gd
```

These are builder inspection frames, not owner acceptance. The owner still needs the signed downloaded-build full-match walkthrough and the separately authorized uncoached reader check recorded in the [epic](../../../Roadmap/02-civilizations-and-world/establish-cdmx-geography-and-maps/README.md).
