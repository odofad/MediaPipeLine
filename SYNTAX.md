# Syntax

The line shapes this project reads and writes. A new shape is added here first, then in the script that uses it. The changelog records the change. Do not invent a form in a script and document it afterwards.

Two shapes. A file uses one of them. Do not mix them.

## Assignment

`pipe.conf`.

```text
key = value
```

The first `=` splits the key from the value. Space around the key and the value is removed. The value is the rest of the line and may contain spaces. A `#` in the value is part of the value. Do not put a comment after a value.

A line whose first non-space character is `#` is a comment. A blank line is ignored. If the value begins and ends with `"`, that one pair of quotes is removed. Quote a value only when you want that. A path does not need quotes.

`pipe.conf` skips a line that is not an assignment. It also skips a key it does not use.

## Card

The mag card. `key: value`, not `key = value`.

The first `:` splits the key from the value. Space around the value is removed when a script reads it back. The key is one lowercase word from the list below. An empty value is written as the word `unknown`. A missing optional line is not the same as `unknown`.

The file is `<folder name>` plus `card_suffix`. The suffix includes the dot. The shipped suffix is `.mag.txt`.

```text
folder: 2026_04_01_New_CX350
date: 2026-04-01
copyright: ...
owner: ...
production:
note:

orphan: clip_002.R3D

clip: clip_001.R3D
id: 2026_04_01_New_CX350_clip_001.R3D_a1b2c
spans: clip_002.R3D clip_003.R3D
width: 1920
height: 1080
frame_rate: 25/1
duration: 12.00
codec: h264
audio: pcm_s16le x 2
timecode: 01:00:00:00
comment:
```

Header, in this order: `folder`, `date`, then `copyright` and `owner` only when those conf values are not empty, then `production`, then `note`, then a blank line.

`date` is `YYYY-MM-DD`, taken from the first ten characters of the folder name.

`production` and `note` are the only header lines a person edits. A rebuild keeps the first of each and does not keep a hand edit of any other header line. It stops reading those two at the first `clip:` or `orphan:` line.

`orphan:` lines follow the header when a RED span has no `_001` in the folder. Then a blank line.

Each clip is one block. Blocks are separated by one blank line. The keys, in this order, are `clip`, `id`, `spans` only when the clip has spans, `width`, `height`, `frame_rate`, `duration`, `codec`, `audio`, `timecode`, `comment`. v1 does not write `camera`, `gamma`, `gamut`, or `range`. Colour detection is on the `research` branch.

`id` is the folder name, the clip filename, and five hex characters, joined by `_`. A rebuild keeps the first `id` already on that clip. A clip with no `id` line gets a new one. `comment` is for a person. A rebuild keeps the first `comment` on that clip and writes an empty one when there is none. An empty comment is not the word `unknown`.

## Names

A shoot folder, and every media file directly inside it, starts with `YYYY_MM_DD_` and the date is a real calendar date. The filename is lowercased before the extension test, so `.R3D` matches `.r3d`. Sidecars and the mag card are not dated.

A name that is written into a log line has no space. The name gate does not reject a space yet. Do not add one.

A RED span is `<stem>_<NNN>.R3D`. `NNN` is three digits. `_001` is the clip. `_002` and higher are spans of that clip and are not probed. The clip id is `<stem>`.

An extension list is dotted, lowercase, and space-separated: `.mxf .mov .mp4`. Do not add an uppercase copy. The test is the lowercased filename, then `endswith`.

## Log

`/var/log/mediapipeline/detect.log`. One line:

```text
2026-09-27T11:54:00+02:00 relog 2026_04_01_New_CX350
```

`date -Iseconds`, one space, then words separated by one space. A later script may split this line. A normal card, a settle skip, and an already-carded skip are not logged.

The verbs:

| Line | When |
| --- | --- |
| `relog <folder>` | The name gate moved the shoot to `2.1.Relog`. |
| `relog-refused <folder>` | A folder of that name was already in `2.1.Relog`. |
| `relog-failed <folder>` | The move failed. |
| `no-media <folder>` | The folder name is a real date and no media file is directly in it. The card is not written. Logged once. |
| `redline-missing <folder> <clip>` | The file is `.r3d` and `redline` was not found. The pass continues and the clip is still carded. |
| `config missing <key>` | A required `pipe.conf` key is empty. |
| `settle_seconds is not a number` | `settle_seconds` is not digits. |
| `logged folder missing <path>` | `logged` is not a directory. |

Stdout is for a person at the terminal. It is not this format. Do not parse it.

## Camscan report

`mediapipeline-camscan` writes one text file per mag. The file is `$HOME/camscan/` plus the mag folder name plus `.txt`. A second run overwrites that file.

It is not a mag card. Detection does not read it. Do not copy it onto a card. A missing tag is the word `none`, not `unknown`. `unknown` stays a card word.

The first lines are a banner, then `key: value` for the mag, the path, the file that was opened, its size in bytes, the slice size, and the scan time. `skipped:` is one media file that was not probed. The reason is `empty`, `too small`, or `unreadable`. A file under 1 MB is `too small`. The line is omitted when the first file opened.

Then sections, in this order. A section is a line `[name]`, then lines, then a blank line. An empty section is the single word `none`. `none` means the read succeeded and the tag was not there.

| Section | What was read |
| --- | --- |
| `ffprobe` | Container and the streams, from the whole file. Colour tags here are ffprobe's, not a camera word. |
| `ffprobe-tags` | Format tags whose names match make, model, colour, or a camera maker. |
| `mediainfo` | Header of the whole file, from `mediainfo --Full --ParseSpeed=0`. Audio is omitted. Colour, transfer, and matrix lines are not a camera word. A missing binary is `not found`. |
| `colour-pairs` | Every media file in the mag, header only. A folder of mags reads only the opened file, then the next mag. `files` and `distinct`, then one line per file: name, codec, bit depth, transfer, primaries, matrix, range, HDR compatibility. An empty field is `-`. Not a camera word. A missing binary is `not found`. |
| `exiftool` | Header tags from the head slice, then the tail slice. No `-ee`. A `head` or `tail` line says which slice. `DeviceSerialNo` of `4294967295` or `0` is omitted. |
| `exiftool-embedded` | `-ee` on those same two slices, stopped at `camscan_timeout` for each. A `head` or `tail` line says which slice. |
| `xml` | Panasonic elements, Sony `Item` attributes, and Sony device elements, from the head and the tail only. |
| `xml-utf16le` | The same slice read as UTF-16LE, including a one-byte shift. |
| `xml-utf16be` | The same slice read as UTF-16BE, including a one-byte shift. |
| `sidecar` | A same-name sidecar beside the file or in `CLIP/`, read in full. If the stem does not match and the mag has one sidecar, that file is read and the section has `note: only sidecar in the mag, stem does not match`. If it has more than one, the section has `note: N sidecars, not guessing` and one `file:` line per name. None of those files is opened. |
| `redline` | `REDline --printMeta` when the file is `.r3d`. Otherwise `not r3d`. A missing binary is `not found`. The report is still written. |

`failed <status>` means the tool exited with no text. The next line is the first line it wrote to stderr. `timed out` means the tool was stopped. Partial lines above it are kept. `not found` means the tool was not on `PATH`.

## Sdscan report

`mediapipeline-sdscan` writes one text file per card dump. The file is `$HOME/sdscan/` plus the folder name plus `.txt`. A second run overwrites that file.

It is not a mag card. Detection does not read it. Do not copy it onto a card. A missing tag is the word `none`, not `unknown`. `unknown` stays a card word.

The first lines are `key: value`: `card`, `path`, `clips`, `sidecars`, `whole`, `scanned`. `tool:` is present when `ffprobe`, `exiftool`, or `mediainfo` was not on `PATH`.

Then sections, in this order. A section is a line `[name]`, then lines, then a blank line. An empty section is the single word `none`.

| Section | What was read |
| --- | --- |
| `layout` | The names directly inside the card folder. |
| `constant` | A tag whose value is the same, and not empty, on at least two clips, and on every clip in that comparison. One line, `tag: value`. A sidecar tag is compared only across clips that have a sidecar. One clip is not a constant. |
| `changes` | A tag that is not the same on every clip. The tag name is a line. Under it, one indented line per clip, `path: value`. A clip with no value is `none`. |
| `missing` | A tag that was empty on every clip. One tag name per line. |
| `clips` | One block per media file, path order. `file`, `bytes`, `read` (`whole` or `head-tail`), `sidecar`, then one `tag: value` line for each tag that clip actually had. Blocks are separated by a blank line. |
| `unpaired` | A sidecar whose name does not match a clip. One path per line. |

The tags, in this order, are `exif.Make`, `exif.Model`, `exif.DeviceManufacturer`, `exif.DeviceModelName`, `exif.CameraModelName`, `exif.DeviceSerialNo`, `exif.Software`, `exif.Encoder`, `exif.CaptureGammaEquation`, `exif.CaptureColorPrimaries`, `exif.CaptureGamma`, `exif.CaptureGamut`, `mi.Encoded_Application`, `ffprobe.encoder`, `ffprobe.make`, `ffprobe.model`, `ffprobe.quicktime.make`, `ffprobe.quicktime.model`, `ffprobe.quicktime.software`, `xml.sony.CaptureGammaEquation`, `xml.sony.CaptureColorPrimaries`, `xml.sony.Model`, `xml.pana.CaptureGamma`, `xml.pana.CaptureGamut`, `xml.pana.ModelName`, `xml.pana.Manufacturer`, and the same `xml` names with the prefix `side` when they were read from a sidecar.

`exif.CaptureGammaEquation` is the raw label. The report does not translate it. A colour tag from the container is not in this list. `side` tags are compared only across clips that have a sidecar.

## Camera rules

Colour rules and camera profiles are not in v1. They are on the `research` branch.

## Folders and scripts

The archive stages are `2.Logged`, `2.1.Relog`, `2.2.Recovery`, `2.3.Error`, `3.Convert`, and `4.Converted`. A new stage takes the next number. It does not rename one of these.

A script in `bin/` is `mediapipeline-<job>`. Its log, when it has one, is `/var/log/mediapipeline/<job>.log`. It is `#!/bin/bash` and `set -euo pipefail`. It reads `/etc/mediapipeline/pipe.conf` for a path or a tunable. It does not hard-code them.
