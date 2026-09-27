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

A bad name goes to `2.1.Relog`. That is the only move. v1 does not read colour, so it does not move a shoot to `2.3.Error`.

Errors are appended to `/var/log/mediapipeline/detect.log`. The path is not in `pipe.conf`. This script does not rotate or summarise that file. A normal card, a settle skip, and an already-carded skip are not logged. The lines a later script can read are `relog`, `relog-refused`, `relog-failed`, `no-media`, and `redline-missing`.

```text
2026-09-27T11:54:00+02:00 no-media 2026_04_01_New_CX350
2026-09-27T11:54:00+02:00 redline-missing 2026_04_01_New_CX350 clip_001.R3D
```

Colour detection and the camera profiles are on the `research` branch. v1 does not read a gamma word, a gamut, a container colour tag, or a camera name from the file or the folder.

## Clip identity

`.r3d` is grouped as a RED clip before `ffprobe`. The clip id is the filename without the final `_NNN`. Only `_001` is a row. `_002` and higher are spans of that `_001` and are not probed. Their names are listed on the `_001` block. A span with no `_001` in the folder is an orphan line on the card.

Every other media file is one row. `ffprobe` fills width, height, frame rate, duration, codec, audio, and timecode. It is not asked for colour.

For RED, those fields come from `REDline --printMeta` when that binary is on `PATH`. `ffprobe` is not run on an `.r3d`. A missing binary logs `redline-missing` and the clip is still carded, with codec `REDCODE`. Gamma and gamut are not read from the REDline text. The `.RMD` is not opened by this script.

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
width: 1920
height: 1080
frame_rate: 30000/1001
duration: 7228.720000
codec: h264
audio: pcm_s24le x 1, pcm_s24le x 1, pcm_s24le x 1, pcm_s24le x 1
timecode: 08:55:11;12
```

An empty value is the word `unknown`, not a blank. One blank line between blocks. There is no `camera`, `gamma`, `gamut`, or `range` line.

The encoder is not built. When it is, it will not find a colour word on this card. Colour readers are on the `research` branch.

## What this script refuses

- It does not scan `convert`.
- It does not encode.
- It does not pair a sidecar by time.
- It does not run the Sony grep on an `.r3d`.
- It does not run the Panasonic grep on an `.r3d`.
- It does not treat a folder suffix such as `_CX350` or `_R3D` as the camera.
- It does not check that the date on a file matches the date on the folder. Both only have to be real dates of the form `YYYY_MM_DD_`.
