# mediapipeline-detect

One shot, one pass. The file will be `bin/mediapipeline-detect`. It does not encode, and it does not move a good folder to `3.Convert`. The starter is `mediapipeline-detect.timer`, every 5 minutes. See [trigger.md](/workspace/artifacts/MediaPipeLine/notes/trigger.md).

Paths, the settle time, the lock, the card suffix, and both extension lists are read from `/etc/mediapipeline/pipe.conf`. The script does not hard-code them. The shipped copy is `pipe.conf` in this tree. `install.sh` copies it to `/etc/mediapipeline/pipe.conf` only when that file is missing, and always refreshes `/etc/mediapipeline/pipe.conf.default`.

An extension matches the way the old `transcode.py` matched. That script kept one tuple:

```python
SUPPORTED_EXTENSIONS = (".mp4", ".mkv", ".avi", ".mov", ".mxf")
if file.lower().endswith(SUPPORTED_EXTENSIONS):
```

`media_extensions` and `sidecar_extensions` are the same kind of list. The filename is lowercased, then tested with `endswith`. `.R3D` matches `.r3d`, and the same is true for `.MXF`, `.MOV`, `.MP4`, and `.MTS`. Uppercase copies are not added to the list. Adding `.mkv` is a change to the conf, not to the script. The old tuple also had `.mkv` and `.avi`. Those are not in `media_extensions` now. `.r3d` and `.mts` are, because detection needs them. The old script had no sidecar list. A sidecar is anything in `sidecar_extensions`.

It watches only the direct children of `logged`. One child folder is one shoot. It does not walk subfolders. A card dump that hides the media in `CLIP/` or `.RDC/` is not seen.

The lock file from `lock_file` is taken non-blocking. If a pass is already running, the new one exits 0. That is what stops a queued timer tick from waiting on a RED `printMeta`.

## Pass

For each child folder:

1. **Settle.** If any file directly in the folder has a modification time newer than `settle_seconds`, skip the folder. This uses modification time only as a copy-still-running check. It is not used to pair sidecars.
2. **Name gate.** The folder name, and every file whose name ends with a `media_extensions` entry, must match `YYYY_MM_DD_` and the date must be a real calendar date. The filename is lowercased before the extension test, so `.R3D` matches `.r3d`. Sidecars and the mag card itself are not checked. One bad name moves the whole folder to `2.1.Relog`. If a folder of that name is already there, the move is refused and the folder stays, with a line on stdout. Nothing is probed.
3. **Already carded.** If `<folder><card_suffix>` exists and every media file is older than that card, skip the folder. If a media file is newer than the card, the card is rebuilt. This runs after the name gate, so a bad name cannot hide behind an old card.
4. **Clips.** Each media file becomes one card block, except a RED span.
5. **Card.** Write the card to a temporary file in the shoot folder and rename it over `<folder><card_suffix>` only when the whole folder has been read.
6. **Unknown colour.** If any clip's gamma or gamut is the word `unknown`, or the conf treatment for that word is `unknown`, move the whole folder to `2.3.Error`. The card goes with it. If a folder of that name is already there, the move is refused and the folder stays in `logged`. A defined treatment, including `rec709-as-is`, stays in `logged`.

A bad name goes to `2.1.Relog`. An undefined gamma or gamut goes to `2.3.Error`. Those are the only moves.

Errors are appended to `/var/log/mediapipeline/detect.log`. The path is not in `pipe.conf`. This script does not rotate or summarise that file. A normal card, a settle skip, and an already-carded skip are not logged. The lines a later script can read are `relog`, `relog-refused`, `relog-failed`, `unresolved`, `error`, `error-refused`, `error-failed`, `redline-missing`, and `conf-write-failed`.

```text
2026-09-27T11:54:00+02:00 unresolved gamma CINE-D 2026_04_01_New_CX350
2026-09-27T11:54:00+02:00 unresolved gamut NEW-GAMUT 2026_04_01_New_CX350
2026-09-27T11:54:00+02:00 error 2026_04_01_New_CX350
```

## Clip identity

`.r3d` is RED before any grep. The clip id is the filename without the final `_NNN`. Only `_001` is a row. `_002` and higher are spans of that `_001` and are not probed. Their names are listed on the `_001` block. A span with no `_001` in the folder is an orphan line on the card. It is not given a gamma.

Any other media file is probed in this order. The first hit wins. A later probe is not allowed to replace it.

1. **Panasonic grep** on the media file:

```bash
grep -a -o -E '<(Manufacturer|ModelName|CaptureGamma|CaptureGamut)>[^<]+' "$file"
```

A Panasonic make is a `Manufacturer` containing `Panasonic`, or a `ModelName` starting with `AG-` or `DC-`, or a `ModelName` containing `Varicam`.

2. **Same-name sidecar**, only when that grep found a Panasonic make and no `CaptureGamma`. The sidecar must be the same basename with an extension from `sidecar_extensions`, beside the file or in a `CLIP` directory inside the shoot folder. Same grep. A different filename is left alone.
3. **Stop as Panasonic** when the make was found and neither the file nor the same-name sidecar has `CaptureGamma`. Gamma and gamut are `unknown`. The Sony grep is not run.
4. **Sony grep**, only when the file had no Panasonic XML at all:

```bash
grep -a -o -E 'Item name="(CaptureGammaEquation|CaptureColorPrimaries)" value="[^"]+"' "$file"
```

A Sony make is `CaptureGammaEquation` present, or a make/model string `ILME-…`, `PXW-…`, or `Sony`. The word `Sony` is only accepted as the make, not as a hit anywhere in the file.
5. **ExifTool**, only when both greps found no camera. The binary is `exiftool` from the conf. Ask for `Make` and `Model` only. A matching make sets the camera. Gamma stays `unknown`. Do not ask ExifTool for `GammaEquation`, `ColorSpace`, or any colour tag.
6. **`other`.** No camera match. Gamma and gamut are `unknown`. The folder goes to `2.3.Error` with the card.

`ffprobe` `color_transfer` is never read. A missing gamma is never written as Rec.709. The Panasonic value is the text inside the tag, including `HD`, `V-Log`, `V-LogL`, and `HLG`. The Sony and RED values are copied the same way.

## Picture fields

For Sony and Panasonic, `ffprobe` from the conf fills width, height, frame rate, duration, codec, audio codec, channel count, and timecode. It is not asked for colour.

For RED, those fields come from the `printMeta` text already captured. The binary is `redline` from the conf. `ffprobe` is not run on an `.r3d`. A non-zero REDline exit is ignored when the gamma line is in the output. No gamma line means gamma and gamut `unknown`. There is no second RED detector. The `.RMD` is not opened by this script. REDline reads it with the `_001`.

`range` is `unknown` on every block. No range probe has been decided.

## Card

`<folder><card_suffix>`, in the shoot folder. The date is the first ten characters of the folder name. `copyright` and `owner` are copied from `pipe.conf` when those values are not empty. A rebuild writes them again from the conf. `production` and `note` are for a person. The script leaves them empty on the first card and copies them onto the new card when it rebuilds. Each is one line.

```text
folder: 2026_04_01_New_CX350
date: 2026-04-01
copyright: Copyright 2026
owner: the house
production: Example
note: 

clip: clip_001.MOV
camera: Panasonic
width: 1920
height: 1080
frame_rate: 30000/1001
duration: 7228.720000
codec: h264
gamma: HD
gamut: BT.709
range: unknown
audio: pcm_s24le x 1, pcm_s24le x 1, pcm_s24le x 1, pcm_s24le x 1
timecode: 08:55:11;12
```

A Panasonic or Sony block has no `spans` line. An empty value is the word `unknown`, not a blank. One blank line between blocks.

The encoder, later, reads `gamma` from this card and does not open the camera file to look for colour. It uses the same `pipe.conf` for `convert`, `converted`, `hevc_root`, and `ffmpeg`.

## What this script refuses

- It does not scan `convert`.
- It does not encode.
- It does not pair a sidecar by time.
- It does not run the Sony grep on an `.r3d`.
- It does not run the Panasonic grep on an `.r3d`.
- It does not treat a folder suffix such as `_CX350` or `_R3D` as the camera.
- It does not check that the date on a file matches the date on the folder. Both only have to be real dates of the form `YYYY_MM_DD_`.
