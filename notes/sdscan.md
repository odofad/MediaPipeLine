# mediapipeline-sdscan

Reads one SD card dump and writes which tags stay the same on every clip, and which tags change. It does not detect. It does not move a file. It does not write a mag card. v1 does not read the report. Colour readers and camera profiles are on the `research` branch.

The command is `mediapipeline-sdscan`. After you pull this tree, install it with `sudo ./install.sh`.

`install.sh` copies `bin/mediapipeline-sdscan` to `/usr/local/bin/`. Do not edit that copy. Edit this tree and install again.

## Run

One folder is one card. Two bodies in one folder make a model tag look like it changes. Copy the card as the camera left it. Do not rename the clips.

```bash
mediapipeline-sdscan /path/to/FS7
mediapipeline-sdscan -h
```

The whole tree is walked. `CLIP/`, `DCIM/`, and `PRIVATE/` are not special. A file whose lowercased name ends with `media_extensions` is a clip. A file that ends with `sidecar_extensions` is a sidecar. An empty file is skipped.

The report is `$HOME/sdscan/<folder name>.txt`. A second run replaces that file. Stdout prints each clip, then the card name, the clip count, the report path, and the `[constant]` lines. That text is not a log line. This script does not write `/var/log/mediapipeline/detect.log`.

## What it reads

ExifTool `-u -fast` is run on the real file, not on a slice. `-fast` stays in the header. The Sony MXF label is hidden unless `-u` is set. The report copies that label as ExifTool printed it. It does not translate it.

`ffprobe` format tags are filtered to encoder, make, model, and the QuickTime make, model, and software tags. Other tags are dropped. `mediainfo --ParseSpeed=0` is asked only for `Encoded_Application`.

The XML grep runs on the whole file when it is at most `sdscan_whole_bytes`. A larger file is grepped at the head and the tail, `camscan_slice` bytes each, and the clip's `read` line says `head-tail`. UTF-16LE and UTF-16BE are decoded and grepped the same way. A same-name sidecar is read in full. Its tags use the prefix `side`.

Each tool stops after `camscan_timeout` seconds, then KILL.

`none` in `[changes]` means that clip did not have the tag. It is not the card word `unknown`.

## Conf

```text
sdscan_whole_bytes = 536870912
```

`camscan_timeout` and `camscan_slice` are shared with camscan. Detection does not read any of the three.

`install.sh` does not write a new key into a live conf that already exists. If `sdscan_whole_bytes` is missing, the script uses `536870912` and says so. Add the line to `/etc/mediapipeline/pipe.conf` when you want the notice to stop.

## How to use a report

`[constant]` is a tag with the same non-empty value on at least two clips, and on every clip in that comparison. A sidecar tag is compared only across clips that have a sidecar. One clip is not enough, so a single sidecar word is listed under `[changes]`. A constant encoder string is not a mode. A colour tag from the container is not in the report, so it cannot become the identifier.

A gamma word in `[changes]` is what a later rule should copy. A model that is constant, with no gamma word anywhere in the report, is the only case for `known-cameras.conf`. One card that was all the same mode is not that case.
