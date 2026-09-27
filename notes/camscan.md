# mediapipeline-camscan

A research probe. It reads one media file in a mag and writes a text report so a camera rule can be written from the tags that are actually there. It does not detect. It does not move a folder. It does not write a mag card. It does not add a treatment. Detection does not read the report.

The command is `mediapipeline-camscan`. It is not a flag on another program. After you pull this tree, install it with `sudo ./install.sh`.

`install.sh` copies `bin/mediapipeline-camscan` to `/usr/local/bin/`. Do not edit that copy. Edit this tree and install again.

## Run

```bash
mediapipeline-camscan
mediapipeline-camscan /path/to/one/mag
mediapipeline-camscan -h
```

No path scans the `error` folder from `/etc/mediapipeline/pipe.conf`.

A path that itself holds media files is one mag. A path that does not is a folder of mags, and each direct child directory is one mag. It does not walk further than that. `CLIP/` and `.RDC/` are not searched for the clip.

The report is `$HOME/camscan/<mag folder name>.txt`. One mag, one file. A second run replaces that file. Stdout prints the mag name, the file it opened, and the path it wrote. That text is not a log line. This script does not write `/var/log/mediapipeline/detect.log`.

## The file it opens

Only a file directly inside the mag, whose lowercased name ends with a `media_extensions` entry, is a candidate. The shipped list is `.mxf .mov .mp4 .r3d .mts`.

Candidates are tried in name order. An empty file is skipped. A file under 1 MB is skipped, and the report says `too small`. A file that both `ffprobe` and ExifTool cannot open is skipped. A `.r3d` of at least 1 MB is taken even when `REDline` is missing, because the file itself is the media. The first file that opens is the one that is probed. It tries at most 8 media files, then writes a report that says `file: none`.

One file is enough to see how that camera writes its words. It is not a check that every clip in the mag matches.

## What it reads

The middle of the file is not read. A grep of a whole MXF is what hung the hand scan.

| Test | What it does |
| --- | --- |
| `ffprobe` | Container, video size, frame rate, codec, audio, and ffprobe's own colour tags, from the whole file. The call uses `-show_format` and `-show_streams`. Those colour tags are not a camera word. |
| `ffprobe-tags` | Format tags whose names look like make, model, colour, or a camera maker. Apple, DJI, and Insta360 often put the model here. |
| `mediainfo` | `mediainfo --Full --ParseSpeed=0` on the whole file. That reads the header and does not walk the picture. General, Other, Image, and Text are kept. Audio is dropped. Video keeps format, size, and colour lines. Colour, transfer, and matrix are not a camera word. Stopped after `camscan_timeout` seconds. |
| `exiftool` | `Make`, `Model`, `Category`, device name, and the gamma tags. `-fast`, no `-ee`. Run on the head slice, then on the tail slice when the file is longer than the slice. The two slices are not joined for this read. `DeviceSerialNo` of `4294967295` or `0` is dropped. `ColorPrimaries` may appear. It is not a camera word. `ColorRangeLevels` is not requested. |
| `exiftool-embedded` | `-ee -fast` on those same two slices, then only lines about gamma, colour, picture profile, device, make, model, or category. Each slice stops after `camscan_timeout` seconds. A `head` or `tail` line says which slice the lines came from. |
| `xml` | Panasonic elements, Sony `Item name` / `value` in either order, and `DeviceManufacturer` / `DeviceModelName`, from the first `camscan_slice` bytes and the last `camscan_slice` bytes. |
| `xml-utf16le` | Those same two slices, decoded as UTF-16LE, including a one-byte shift. Sony MXF often stores the XML this way, which is why a plain grep misses it. |
| `xml-utf16be` | The same slices as UTF-16BE. |
| `sidecar` | A same-name sidecar beside the clip or in `CLIP/`, read in full. If there is no same-name file and the mag has exactly one sidecar, that file is read and the section says the stem does not match. If it has more than one, the names are listed and none is opened. Sidecars are small. The clip is not. |
| `redline` | `REDline --printMeta` when the file ends in `.r3d`. Otherwise the section says `not r3d`. The binary is optional. A missing one writes `not found` and the report is still written. |

`none` means that test ran and found nothing. It is not the card word `unknown`. `failed` and a status means the tool exited with no text. The next line is its first error line. `timed out` means the tool was stopped. Lines above it are kept. `not found` means that tool is not on `PATH`.

The shape of the file is in [SYNTAX.md](../SYNTAX.md).

## Conf

Paths, the extension lists, and the tool names come from `/etc/mediapipeline/pipe.conf`. Two keys belong to this script. Detection does not read them.

```text
camscan_slice = 8388608
camscan_timeout = 25
```

`camscan_slice` is how many bytes are taken from the head and again from the tail. `camscan_timeout` is how many seconds one ExifTool `-ee` call on one slice is allowed to run, how many seconds `REDline` is allowed, and how many seconds `mediainfo` is allowed. `ffprobe` and the header ExifTool call stop after 15 seconds. The header call is also one slice at a time.

`install.sh` does not write these two lines into a live conf that already exists. If they are missing, the script uses `8388608` and `25` and says so on stdout. Add the two lines to `/etc/mediapipeline/pipe.conf` when you want the notice to stop. Do not put them only in the shipped `pipe.conf` and expect the live file to change. The next install will not copy them over.

## How to use a report

Read `mediainfo`, `exiftool`, `exiftool-embedded`, and the three `xml` sections. A camera rule is written only for a tag that appears there. `ffprobe` colour is evidence, not the word the card should copy. MediaInfo colour, transfer, and matrix are the same kind of evidence.

If the file has a gamma word, that word is what goes on the card later. The treatment for it belongs in `pipe.conf`, not in this report. If the file has a model and no gamma word, do not invent one. The FDR-AX53 is that case: `DeviceModelName` is `FDR-AX53`, and no gamma word is stored. Version 1 of `camera-rules.conf` cannot say that yet. This script does not add the rule.
