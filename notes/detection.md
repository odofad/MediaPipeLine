# mediapipeline-detect

One shot, one pass. The file will be `bin/mediapipeline-detect`. It does not encode, and it does not move a good folder to `3.Convert`. The starter is `mediapipeline-detect.timer`, every 5 minutes. See [trigger.md](/workspace/artifacts/MediaPipeLine/notes/trigger.md).

Line shapes for the conf, the mag card, and the log are [SYNTAX.md](../SYNTAX.md).

Paths, the settle time, the lock, the card suffix, and both extension lists are read from `/etc/mediapipeline/pipe.conf`. The script does not hard-code them. The shipped copy is `pipe.conf` in this tree. `install.sh` copies it to `/etc/mediapipeline/pipe.conf` only when that file is missing, and always refreshes `/etc/mediapipeline/pipe.conf.default`.

An extension matches the way the old `transcode.py` matched. That script kept one tuple:

```python
SUPPORTED_EXTENSIONS = (".mp4", ".mkv", ".avi", ".mov", ".mxf")
if file.lower().endswith(SUPPORTED_EXTENSIONS):
```

`media_extensions` and `sidecar_extensions` are the same kind of list. The filename is lowercased, then tested with `endswith`. `.R3D` matches `.r3d`, and the same is true for `.MXF`, `.MOV`, `.MP4`, and `.MTS`. Uppercase copies are not added to the list. Adding `.mkv` is a change to the conf, not to the script. The old tuple also had `.mkv` and `.avi`. Those are not in `media_extensions` now. `.r3d` and `.mts` are, because detection needs them. The old script had no sidecar list. A sidecar is anything in `sidecar_extensions`.

It watches only the direct children of `logged`. One child folder is one shoot. It does not walk subfolders. A card dump that hides the media in `CLIP/` or `.RDC/` is not a shoot. A dated folder with no media file directly in it is not carded. The pass logs `no-media` once and leaves the folder in `logged`. Flattening the card is the ingest step. `mediapipeline-sdscan` is the tool that walks a card.

The lock file from `lock_file` is taken non-blocking. If a pass is already running, the new one exits 0. That is what stops a queued timer tick from waiting on a RED `printMeta`.

## Pass

For each child folder:

1. **Settle.** If any file directly in the folder has a modification time newer than `settle_seconds`, skip the folder. This uses modification time only as a copy-still-running check. It is not used to pair sidecars.
2. **Name gate.** The folder name, and every file whose name ends with a `media_extensions` entry, must match `YYYY_MM_DD_` and the date must be a real calendar date. The filename is lowercased before the extension test, so `.R3D` matches `.r3d`. Sidecars and the mag card itself are not checked. One bad name moves the whole folder to `2.1.Relog`. If a folder of that name is already there, the move is refused and the folder stays, with a line on stdout. Nothing is probed.
3. **No media.** If no file directly in the folder ends with a `media_extensions` entry, do not write a card. Print `no media` and log `no-media` the first time. Later passes print the line and do not log it again. The folder stays in `logged`.
4. **Already carded.** If `<folder><card_suffix>` exists and every media file is older than that card, skip the folder. If a media file is newer than the card, the card is rebuilt. This runs after the name gate, so a bad name cannot hide behind an old card.
5. **Clips.** Each media file becomes one card block, except a RED span.
6. **Card.** Write the card to a temporary file in the shoot folder and rename it over `<folder><card_suffix>` only when the whole folder has been read.
7. **Unknown colour.** If any clip's gamma or gamut is the word `unknown`, or the conf treatment for that word is `unknown`, move the whole folder to `2.3.Error`. The card goes with it. If a folder of that name is already there, the move is refused and the folder stays in `logged`. A defined treatment, including `rec709-as-is`, stays in `logged`.

A bad name goes to `2.1.Relog`. An undefined gamma or gamut goes to `2.3.Error`. Those are the only moves.

Errors are appended to `/var/log/mediapipeline/detect.log`. The path is not in `pipe.conf`. This script does not rotate or summarise that file. A normal card, a settle skip, and an already-carded skip are not logged. The lines a later script can read are `relog`, `relog-refused`, `relog-failed`, `no-media`, `unresolved`, `error`, `error-refused`, `error-failed`, `redline-missing`, and `conf-write-failed`.

```text
2026-09-27T11:54:00+02:00 unresolved gamma CINE-D 2026_04_01_New_CX350
2026-09-27T11:54:00+02:00 unresolved gamut NEW-GAMUT 2026_04_01_New_CX350
2026-09-27T11:54:00+02:00 error 2026_04_01_New_CX350
```

## Camera rules

Where a camera writes its word is `camera-rules.conf`. The grammar is version 1, in the header of that file. `mediapipeline-camera-rules` checks the file. It does not probe a clip.

This script does not read that file yet. The steps below are still what runs. Change a reader here and change the rule in the same commit. See [camera-rules.md](camera-rules.md).

The archivist ends the folder name with the camera. A clip name is longer. The house pattern is `Year_Month_Day_Place_Persons_Content_CameraModel_ClipNumber_OptionalSubInfo`, as in `2020_11_27_Boston_WiumBrent_NgatiLionPride_FS5_01_SingleFemaleWithMale`. The camera is the field before the clip number, not whatever is last. Detection does not read either word yet. The word can name the body when the file itself has none. It cannot choose the gamma. An FS5, an FS7, and an A7 shoot more than one picture. A mixed mag is still a logging problem. The folder may say A7 while one clip in it is an FX6. See [archive.md](archive.md).

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
4. **Sony grep**, only when the file had no Panasonic XML at all. Two shapes. The `Item name=` shape:

```bash
grep -a -o -E 'Item name="(CaptureGammaEquation|CaptureColorPrimaries|Make|Manufacturer|Model|ModelName|CameraModelName)" value="[^"]+"' "$file"
```

And the `Device` shape the AX53 actually writes:

```bash
grep -a -o -E '<Device[[:space:]][^>]*>' "$file"
```

`manufacturer="Sony"` is the make. `modelName` is the model. It is not thrown away for failing the make test. A Sony make is `CaptureGammaEquation` present, or a make string `Sony`. The word `Sony` is only accepted as the make, not as a hit anywhere in the file. `ILME-` and `PXW-` in the rule file are not matched by this script yet.
5. **Known camera from that model**, when `modelName` or an Item model was read. The file is `/etc/mediapipeline/known-cameras.conf`. An exact model replaces `camera`, `gamma`, and `gamut`, including a `CaptureGammaEquation` on the same clip. A model that is not listed leaves the equation in place. `FDR-AX53` is `rec709` and `rec709`. This does not use ExifTool.
6. **Sony MXF label**, only when that grep found no Sony item and no `Device` tag. The binary is `exiftool` from the conf. The gamma command is `exiftool -u -fast -m -s3 -CaptureGammaEquation` on the real file, stopped after 25 seconds when `timeout` exists. `-u` is required. Without it, ExifTool hides this tag. `-fast` stays in the header. The label `060e2b34.0401.0101.04010101.01020000` is written as `rec709`. Any other value is copied as printed. This was read on the opened FS5. It is not claimed for every FS7 mag. When that gamma word is set, a second command reads `ColorPrimaries` with `-b`. The 16 bytes `060e2b34040101060401010103030000` are written as `rec709`. Any other bytes, including a Sony private label, leave the gamut empty. `ColorimetryCode` is the matrix and is not read. A private acquisition tail is not read. This is still camera `Sony`.
7. **ExifTool make**, only when the label is also missing. Ask for `Make` and `Model` only. A matching make sets the camera. Gamma stays `unknown`. Do not ask ExifTool for `ColorSpace` or any picture colour tag.
8. **`other`.** No camera match. Gamma and gamut are `unknown`. The folder goes to `2.3.Error` with the card.

Apple, DJI, and Insta360 match on the make or the model and write that camera on the card. They do not write a gamma word from the make. An empty gamma still sends the folder to `2.3.Error`, unless step 9 matches a known model. `iPhone 17 Pro Max` is that exception.
9. **Known camera from ExifTool**, only when the clip still has no gamma word and step 5 did not see a model in the file. ExifTool is asked for `Model`, `DeviceModelName`, and `CameraModelName`. An exact model line sets `camera`, `gamma`, and `gamut` from that block. `iPhone 17 Pro Max` is `HLG` and `BT.2020`. A model that is not listed stays `unknown`.

`ffprobe` `color_transfer` is never read. A missing gamma is never written as Rec.709 unless that model is listed in `known-cameras.conf`. The Panasonic value is the text inside the tag, including `HD`, `V-Log`, `V-LogL`, and `HLG`. The Sony and RED values are copied the same way.

## Picture fields

For Sony and Panasonic, `ffprobe` from the conf fills width, height, frame rate, duration, codec, audio codec, channel count, and timecode. It is not asked for colour.

For RED, those fields come from the `printMeta` text already captured. The binary is `redline` from the conf. An empty key means `REDline` on `PATH`. `ffprobe` is not run on an `.r3d`. A missing binary logs `redline-missing` and does not stop the pass. A non-zero REDline exit is ignored when the gamma line is in the output. No gamma line means gamma and gamut `unknown`, and that folder goes to Error with any other unresolved shoot. There is no second RED detector. The `.RMD` is not opened by this script. REDline reads it with the `_001`.

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
