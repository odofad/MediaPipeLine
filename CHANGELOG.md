# Changelog

Newest first.

## 2026-09-27 — sdscan

`mediapipeline-sdscan` reads one card dump and writes `$HOME/sdscan/<folder>.txt`. `[constant]` is the tag that is the same on every clip. `[changes]` is the tag that is not. ExifTool `-u -fast` runs on the real file. The XML of a file up to `sdscan_whole_bytes` is read in full. A larger file is head and tail. The report does not translate a Sony label and it does not list container colour.

## 2026-09-27 — iPhone 17 Pro Max in known cameras

The error-folder scan had one exact model string: `iPhone 17 Pro Max`. That block is `HLG` / `BT.2020` / `Apple`. `gamut.BT.2020` is `bt2020`, a name with no LUT yet. `DJI FLIP` is an encoder string, not a model, and that body can shoot D-Log, so it is not a block. Sony Mem, the A7 XML, the Small Sony, and the Insta360 did not add a row. Sony Mem is shared. The A7 already has a gamma word. The other two had no model string.

## 2026-09-27 — folder scan walks mags

A scan of a folder of mags reads one opened file in each mag, then the next mag. `colour-pairs` on that run is that one file. Point camscan at one mag to read every clip. The terminal prints each file it tries. `timeout` sends KILL if a tool ignores TERM.

## 2026-09-27 — camscan colour pairs

`mediapipeline-camscan` writes a `colour-pairs` section. It is one header line from MediaInfo for every media file in the mag: codec, bit depth, transfer, primaries, matrix, range, and HDR compatibility. `distinct` is how many different lines that produced. The section is evidence. It is not a camera word, and detection does not read it.

MediaInfo does not treat `\t` in an Inform template as a tab, so the first run printed the backslash and then padded empty columns. The template now separates fields with `|`.

## 2026-09-27 — Apple, DJI, Insta360 named only

Three `exiftool-make` rules name the camera and do not read colour. `Apple`, `DJI`, and `Insta360` are written on the card. Gamma and gamut stay empty, so the folder still goes to `2.3.Error`. They are not in `known-cameras.conf`.

## 2026-09-27 — known cameras

`known-cameras.conf` lists a body that stores no gamma word and has no log picture. Detection uses it only when the clip's own gamma word is missing. The model match is exact. `FDR-AX53` is `rec709` / `rec709`. `install.sh` copies the file over the live one. The phone, the DJI, and the Insta360 are not listed.

## 2026-09-27 — Sony MXF gamma label

FS5 and FS7 store `CaptureGammaEquation` as a SMPTE label. Detection asks ExifTool for that one tag with `-u -fast` when the Sony XML grep misses. The label read on both bodies is written as `rec709`. `gamma.rec709` is `rec709-as-is`. Gamut is still empty on those files, so the shoot stays in Error until a gamut word exists.

## 2026-09-27 — mediainfo filter

The first MediaInfo reports kept file-size lines and dropped `Other #1`, which is where an MXF puts acquisition metadata. Camscan now keeps every `Other` block and drops the size lines.

## 2026-09-27 — mediainfo

Camscan now runs `/usr/bin/mediainfo` on the whole file and writes a `[mediainfo]` section. `--ParseSpeed=0` reads the header and does not walk the picture. Audio blocks are dropped. Colour, transfer, and matrix lines are not a camera word. Detection does not read the section. `install.sh` installs the `mediainfo` package and stops if `/usr/bin/mediainfo` does not start.

## 2026-09-27 — installer

`install.sh` now follows `notes/platform.md`. It stops unless the machine is Ubuntu 26.04. It installs `ffmpeg` and `libimage-exiftool-perl` from Ubuntu, then runs `/usr/bin/ffprobe -version` and `/usr/bin/exiftool -ver`. Either failure stops the install. A missing `REDline` is still only a warning. A live conf is still not overwritten.

## 2026-09-27 — platform

`notes/platform.md` is the rule for binaries. Ubuntu Server 26.04 is the only target. A tool Ubuntu ships is run from `/usr/bin`, even when the conf names a different path. `REDline` is the exception, because Ubuntu does not ship it. Jellyfin is not an exception.

Detection, camscan, and status now follow that rule. `ffmpeg`, `ffprobe`, and `exiftool` resolve to `/usr/bin` when the file is there. Camscan does the same for `timeout` and `iconv`. Status does the same for `systemctl` and `nvidia-smi`.

## 2026-09-27 — system ffmpeg

The shipped `ffmpeg` line is the name `ffmpeg`, not `/usr/lib/jellyfin-ffmpeg/ffmpeg`. Ubuntu 26.04 installs that binary from the `ffmpeg` package in universe (8.0.1). Jellyfin's build is not in Ubuntu. It comes from Jellyfin's own apt repository and is installed beside the system binary. A live conf is not overwritten by `install.sh`, so a machine that already points at Jellyfin keeps that line until it is edited.

## 2026-09-27 — REDline optional

`install.sh` does not install REDline. When the binary named by `redline` is not on `PATH`, the install finishes and prints a warning. Detection and camscan no longer refuse to start because that conf key is empty. An empty key means `REDline`. A `.r3d` with no binary is still gamma `unknown` and that shoot goes to Error. The pass continues, and every other camera is read.

## 2026-09-27 — camscan read

The first sixteen reports had an empty ffprobe section on every file, including a 5 MB phone clip. ExifTool `-ee` was run on the whole clip and timed out on the large MP4s. A 936 byte file was treated as media. No camera rule is added.

ffprobe now asks for the format and the streams. A tool that exits with no text is `failed` and the status, plus its first error line. `none` is only a read that succeeded and had no tag. `timed out` is unchanged.

The header read and `-ee` run on the head slice and the tail slice as two files, with `-fast`. They are not run on the original, and the two slices are not glued together for ExifTool. The XML grep still uses both ends. `Category` is requested. `DeviceSerialNo` of `4294967295` or `0` is dropped. `ColorRangeLevels` is not requested. `ColorPrimaries` stays in the report and is not a camera word.

A media file under 1 MB is skipped as `too small`. A same-name sidecar is still read first. If there is none, and the mag has one sidecar, that file is read. If it has more than one, the names are listed and none of them is opened.

## 2026-09-27 — default paths

The shipped folder paths are `/var/lib/mediapipeline/archive` and `/var/lib/mediapipeline/encode`. `install.sh` uses those only when the live conf has no path yet. A machine that already has a conf keeps the paths it is asked to keep. Notes and the README no longer name a particular pool.

## 2026-09-27 — readme

The README is a description of the pipeline and its current goals. Install steps are no longer the front of the file. The short GitHub description matches that.

## 2026-09-27 — camscan

`mediapipeline-camscan` probes one openable media file per mag and writes `$HOME/camscan/<mag name>.txt`. It does not move a folder and it does not write a mag card. The middle of the file is not grepped. XML is taken from `camscan_slice` bytes at the head and the tail, as UTF-8 and as UTF-16. ExifTool `-ee` and `REDline` stop after `camscan_timeout` seconds. Those two keys are in `pipe.conf`. A live conf that does not have them yet still runs, and the script says it is using `8388608` and `25`.

How to run it, how the file is chosen, and what each section is for are in `notes/camscan.md`. The report shape is in `SYNTAX.md`. A missing tag is `none`, not `unknown`. ffprobe colour tags are recorded and are not a camera word.

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
