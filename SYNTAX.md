# Syntax

The line shapes this project reads and writes. A new shape is added here first, then in the script that uses it. The changelog records the change. Do not invent a form in a script and document it afterwards.

Two shapes. A file uses one of them. Do not mix them.

## Assignment

`pipe.conf` and `camera-rules.conf`.

```text
key = value
```

The first `=` splits the key from the value. Space around the key and the value is removed. The value is the rest of the line and may contain spaces. A `#` in the value is part of the value. Do not put a comment after a value.

A line whose first non-space character is `#` is a comment. A blank line is ignored. If the value begins and ends with `"`, that one pair of quotes is removed. Quote a value only when you want that. A path does not need quotes.

`pipe.conf` skips a line that is not an assignment. It also skips a key it does not use, so a treatment line can sit in the same file. `camera-rules.conf` rejects a line that is not an assignment, and it rejects a key that version 1 does not list.

A key may be repeated only where that file says so. In `camera-rules.conf` the list keys may be repeated, one entry per line. Every other key is once per rule.

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
spans: clip_002.R3D clip_003.R3D
camera: Panasonic
width: 1920
height: 1080
frame_rate: 25/1
duration: 12.00
codec: h264
gamma: V-Log
gamut: V-Gamut
range: unknown
audio: pcm_s16le x 2
timecode: 01:00:00:00
```

Header, in this order: `folder`, `date`, then `copyright` and `owner` only when those conf values are not empty, then `production`, then `note`, then a blank line.

`date` is `YYYY-MM-DD`, taken from the first ten characters of the folder name.

`production` and `note` are the only lines a person edits. A rebuild keeps the first of each and does not keep a hand edit of any other line. It stops reading those two at the first `clip:` or `orphan:` line.

`orphan:` lines follow the header when a RED span has no `_001` in the folder. Then a blank line.

Each clip is one block. Blocks are separated by one blank line. The keys, in this order, are `clip`, `spans` only when the clip has spans, `camera`, `width`, `height`, `frame_rate`, `duration`, `codec`, `gamma`, `gamut`, `range`, `audio`, `timecode`. `range` is `unknown` until a script has a real value for it.

`camera` is the word a camera rule sets, or `other` when no rule matches. `gamma` and `gamut` are the camera's own words. They are not renamed to a treatment on the card. The treatment is the `gamma.` or `gamut.` line in `pipe.conf`. The key is that card word, capitals included. `gamma.HD` matches `gamma: HD`. It does not match `hd`.

## Names

A shoot folder, and every media file directly inside it, starts with `YYYY_MM_DD_` and the date is a real calendar date. The filename is lowercased before the extension test, so `.R3D` matches `.r3d`. Sidecars and the mag card are not dated.

A name that is written into a log line has no space. The name gate does not reject a space yet. Do not add one.

A RED span is `<stem>_<NNN>.R3D`. `NNN` is three digits. `_001` is the clip. `_002` and higher are spans of that clip and are not probed. The clip id is `<stem>`.

An extension list is dotted, lowercase, and space-separated: `.mxf .mov .mp4`. Do not add an uppercase copy. The test is the lowercased filename, then `endswith`.

## Log

`/var/log/mediapipeline/detect.log`. One line:

```text
2026-09-27T11:54:00+02:00 unresolved gamma CINE-D 2026_04_01_New_CX350
```

`date -Iseconds`, one space, then words separated by one space. A later script may split this line. A normal card, a settle skip, and an already-carded skip are not logged.

The verbs:

| Line | When |
| --- | --- |
| `relog <folder>` | The name gate moved the shoot to `2.1.Relog`. |
| `relog-refused <folder>` | A folder of that name was already in `2.1.Relog`. |
| `relog-failed <folder>` | The move failed. |
| `unresolved gamma unknown <folder>` | A clip had no gamma word. `gamut` is the same shape. |
| `unresolved gamma <word> <folder>` | The word was read and its treatment is missing or `unknown`. |
| `error <folder>` | The shoot was moved to `2.3.Error`. |
| `error-refused <folder>` | A folder of that name was already in `2.3.Error`. |
| `error-failed <folder>` | The move failed. |
| `redline-missing <folder> <clip>` | The file is `.r3d` and `redline` was not found. |
| `conf-write-failed <gamma.word> <folder>` | The new treatment line could not be appended. |
| `config missing <key>` | A required `pipe.conf` key is empty. |
| `settle_seconds is not a number` | `settle_seconds` is not digits. |
| `logged folder missing <path>` | `logged` is not a directory. |

Stdout is for a person at the terminal. It is not this format. Do not parse it.

## Camscan report

`mediapipeline-camscan` writes one text file per mag. The file is `$HOME/camscan/` plus the mag folder name plus `.txt`. A second run overwrites that file.

It is not a mag card. Detection does not read it. Do not copy it onto a card. A missing tag is the word `none`, not `unknown`. `unknown` stays a card word.

The first lines are a banner, then `key: value` for the mag, the path, the file that was opened, its size in bytes, the slice size, and the scan time. `skipped:` is one unopened media file. It is omitted when the first file opened.

Then sections, in this order. A section is a line `[name]`, then lines, then a blank line. An empty section is the single word `none`.

| Section | What was read |
| --- | --- |
| `ffprobe` | Container and the first video and audio streams. Colour tags here are ffprobe's, not a camera word. |
| `ffprobe-tags` | Format tags whose names match make, model, colour, or a camera maker. |
| `exiftool` | Header tags only. No `-ee`. |
| `exiftool-embedded` | The same file with `-ee`, stopped at `camscan_timeout`. |
| `xml` | Panasonic elements, Sony `Item` attributes, and Sony device elements, from the head and the tail only. |
| `xml-utf16le` | The same slice read as UTF-16LE, including a one-byte shift. |
| `xml-utf16be` | The same slice read as UTF-16BE, including a one-byte shift. |
| `sidecar` | A same-name sidecar beside the file or in `CLIP/`, read in full. |
| `redline` | `REDline --printMeta` when the file is `.r3d`. Otherwise `not r3d`. |

`timed out` means the tool was stopped. Partial lines above it are kept. `not found` means the tool was not on `PATH`.

## Camera rules

`camera-rules.conf` uses the assignment line, then adds three rules of its own. `version = 1` comes before the first rule. A rule starts at `family` and ends at the next `family`. The closed lists for `applies`, `read`, `match`, and the other keys are the header of that file. `mediapipeline-camera-rules` checks them. Detection does not read the file yet.

A new key in that file is a new version, written here and in that header in the same commit.

## Folders and scripts

The archive stages are `2.Logged`, `2.1.Relog`, `2.2.Recovery`, `2.3.Error`, `3.Convert`, and `4.Converted`. A new stage takes the next number. It does not rename one of these.

A script in `bin/` is `mediapipeline-<job>`. Its log, when it has one, is `/var/log/mediapipeline/<job>.log`. It is `#!/bin/bash` and `set -euo pipefail`. It reads `/etc/mediapipeline/pipe.conf` for a path or a tunable. It does not hard-code them.
