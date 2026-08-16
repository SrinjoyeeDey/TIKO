# Panda animation assets

These transparent PNG sequences are Flutter-ready character frames. The inspected idle sprite strip contains eight panda components; each was detected from its real pixel boundary (rather than equal-width slicing). The available source material also contains eight candidate frames each for `thinking`, `correct`, `celebrate`, `wrong_sad`, and `appear`; the pipeline removes edge-connected white backgrounds and detached decorations.

`appear` frames 03–07 visibly contain incomplete/overlapping character material in the supplied pre-extracted input. They are preserved as a traceable partial result, but must be regenerated from the original sprite sheet before game use.

Suggested playback rates: idle 6–8 FPS, thinking 8–10 FPS, correct 10–12 FPS, celebrate 10–12 FPS, wrong_sad 8–10 FPS, and appear 10–12 FPS. Exact generated paths, canvas dimensions, and counts are in `manifest.json`.

To regenerate (the source is read-only and never modified):

```powershell
& <bundled-python> tools/process_panda_sprite_sheet.py --source-frames <verified-frame-folder> --idle-sprite <idle-sprite-strip.png>
```

The script replaces only generated animation folders, writes RGBA PNGs, preserves alpha, pads frames consistently within each animation, updates `manifest.json`, and creates contact sheets in `previews/`.

In Flutter, load a frame by its manifest path prefixed with `assets/animations/panda/`. Add the directory to `pubspec.yaml` only in the actual Flutter project.
