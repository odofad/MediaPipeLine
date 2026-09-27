# Changelog

Newest first.

## 2026-09-27 — syntax

`SYNTAX.md` is the line shapes the project already uses. A new shape is added there before a script starts writing it.

Assignment is `key = value`, in `pipe.conf` and `camera-rules.conf`. A `#` after a value is part of the value. One pair of surrounding double quotes is removed. `pipe.conf` skips a key it does not use. `camera-rules.conf` rejects an unknown key. The checker now strips quotes the same way the conf reader does.

The mag card is `key: value`. The header, the orphan lines, and the clip block are listed in order. `unknown` means the value was empty. `production` and `note` stay the only hand-edited lines.

The detect log is `date -Iseconds`, one space, then a verb from the list in that file. Stdout is not that format.

## 2026-09-27 — camera rules

`camera-rules.conf` is version 1 of the camera rule file. It says where a camera writes its own word. It does not say what the encoder does with that word. Treatments stay in `pipe.conf`.

The grammar is the header of that file. A rule is `family`, `applies`, `read`, `match`, and `camera`, plus the tag and pattern lists those reads need. An unknown key or a value outside its list is an error. A new key is a new version.

The five rules are the readers detection already uses: RED, Panasonic XML, Sony `name` then `value`, then ExifTool make for Panasonic and Sony. ExifTool is not asked for colour. The Sony attribute order `either` is legal and unused. FS5, FS7, SmallSony, phone, DJI, and Insta360 are not rules.

`mediapipeline-camera-rules` checks the file. It does not open a clip. `mediapipeline-detect` does not read the file yet. The file is not copied to `/etc/mediapipeline/`.

## 2026-09-27 — status screen

`mediapipeline-status` no longer lists the archive folders by directory name. It reports the logging pass and the encoder as three states each.

Logging:

- `unprocessed` is a shoot still in `2.Logged` with no mag card.
- `completed` is a shoot still in `2.Logged` with a mag card. The colour was resolved. Detection does not move it to `3.Convert`.
- `failed` is `2.3.Error`. Unknown gamma or gamut put the whole shoot there, card included.
- `relog` is `2.1.Relog`. The folder name, or a media filename, does not start with a real `YYYY_MM_DD_`. That is a mistake from the logging step before detection. The shoot is not probed. A person fixes the names and moves it back to `2.Logged`.
- `recovery` is printed only when `2.2.Recovery` is not empty.

Encoder:

- `queue` is `3.Convert`.
- `completed` is `4.Converted`.
- `failed` is `0`. There is no encode-failure folder yet.
- The heading stays `not installed` until `mediapipeline-encode.service` exists.

The encode output path is not listed. It is a tree of finished files, not a count of jobs. The card name is `card_suffix` from `pipe.conf`. An empty suffix is `.mag.txt`.

`notes/status.md` and the status paragraph in `README.md` match this screen.
