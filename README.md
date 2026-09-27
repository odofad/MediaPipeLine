# MediaPipeLine

The archive pipeline. Camera originals land in a shoot folder. v1 writes a mag card for that folder and stops. It does not read colour. Colour detection and the camera profiles are on the `research` branch.

The card records the clip, a stable id, a comment a person can fill later, and the picture ffprobe can see: size, frame rate, duration, codec, audio, and timecode. It does not record a camera, a gamma, or a gamut.

The master copy is this tree. `install.sh` puts the scripts into the system locations. Archive and encode paths stay in the live conf on that machine. The shipped defaults are under `/var/lib/mediapipeline/`.

## Where it stands

Detection runs on a timer. One pass writes a mag card and stops. A folder name that is not a real date goes to Relog. A dated folder with media stays in Logged, card and all. Nothing is moved for colour. Nothing is moved to Convert, and nothing is encoded.

REDline is not part of the install. The install warns when it is missing. A `.r3d` on that machine is still carded. The codec line is `REDCODE`, and the picture fields are empty until REDline is there.

`mediapipeline-status` reports the logging pass and the encoder. The encoder is not installed.

`mediapipeline-camscan` and `mediapipeline-sdscan` are research probes. They do not write a card and they do not move a folder. The colour readers that used those reports are on `research`, not in v1.

## Where it is going

Colour comes back from the `research` branch when a reader is settled. The encoder comes after that. v1 does not choose a CRF or a LUT.

## Tree

```text
MediaPipeLine/
  install.sh          copies this tree into the system locations
  pipe.conf           shipped paths, tunables, and extensions
  SYNTAX.md           the line shapes the conf, the card, the log, a camscan report, and an sdscan report share
  bin/                the scripts
  systemd/            the detection timer
  notes/              the plan for each script
  notes/platform.md   Ubuntu 26.04, system binaries, and the installer plan
  CHANGELOG.md        what changed, newest first
```

Tunables live in `/etc/mediapipeline/pipe.conf`. A later install does not overwrite that file. It only refreshes `pipe.conf.default`, and it asks again for the archive root and the encode output.
