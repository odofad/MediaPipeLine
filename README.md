# MediaPipeLine

The archive pipeline. Camera originals land in a shoot folder. The picture is named from the camera's own words. An encode happens later, and only when that name already has a treatment.

The card keeps the camera's gamma and gamut. It does not rename them. `pipe.conf` says what the encoder does with each word. A word with no treatment is not encoded. A missing word is not filled in as Rec.709.

The master copy is this tree. `install.sh` puts the scripts into the system locations. Archive and encode paths stay in the live conf on that machine. The shipped defaults are under `/var/lib/mediapipeline/`.

## Where it stands

Detection runs on a timer. One pass writes a mag card and stops. A folder name that is not a real date goes to Relog. Unknown colour goes to Error. A shoot whose colour is resolved stays in Logged. Nothing is moved to Convert, and nothing is encoded.

The cameras detection can already read are RED, Panasonic, and the Sony bodies that write `CaptureGammaEquation`. `camera-rules.conf` is version 1 of that list. It says where a camera writes its word. It does not say what the encoder does with it. Detection does not read the file yet. The readers in the script are still what runs. `mediapipeline-camera-rules` only checks the grammar.

`mediapipeline-status` reports the logging pass and the encoder. The encoder is not installed.

`mediapipeline-camscan` opens one file in a mag and writes a report. It does not move the folder and it does not write a card. That report is how an unknown camera gets a rule. The first one read this way is the FDR-AX53: the model is in the file, and no gamma word is stored.

## Where it is going

A camera that still fails gets a rule only after its report shows the tag. Detection then reads the rule file instead of the readers written into the script. The encoder comes after that, and only for a treatment that is already decided. `rec709-as-is` is the decided case: the picture is already HD, so it is not converted. Every other treatment is a name. The filter or LUT for it is not chosen yet.

## Tree

```text
MediaPipeLine/
  install.sh          copies this tree into the system locations
  pipe.conf           shipped paths, tunables, extensions, and treatments
  camera-rules.conf   where a camera writes its gamma word
  SYNTAX.md           the line shapes the conf, the card, the log, and a camscan report share
  bin/                the scripts
  systemd/            the detection timer
  notes/              the plan for each script
  CHANGELOG.md        what changed, newest first
```

Tunables live in `/etc/mediapipeline/pipe.conf`. A later install does not overwrite that file. It only refreshes `pipe.conf.default`, and it asks again for the archive root and the encode output.
