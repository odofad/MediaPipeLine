# Camera rules

The assignment line is [SYNTAX.md](../SYNTAX.md). `camera-rules.conf` uses that line, then adds the grammar in its header. Version 1. `mediapipeline-camera-rules` checks the file and prints the rule names. It does not open a clip.

`mediapipeline-detect` does not read the file yet. The readers in the script are still what runs. A change to a reader and a change to the rule are the same commit. Do not add a camera in the script that is not a rule.

The file is not installed to `/etc/mediapipeline/`. Nothing in the timer reads it.

## What a rule is

One family. One place the word is written. The first rule that matches sets `camera`, `gamma`, and `gamut`. An empty gamma does not fall through to the next rule. No match leaves `camera` as `other` and gamma empty. The card still writes `unknown`. `pipe.conf` decides the treatment. A treatment is not a line in this file.

`.r3d` is only offered to `applies = r3d`, and those rules are first. Every other media file walks the `other-media` rules in file order.

## The five rules

| family | read | matches when |
| --- | --- | --- |
| `red` | REDline `printMeta` | the file is `.r3d`, even if the tags are empty |
| `panasonic` | `<Tag>word</Tag>` in the file | `CaptureGamma`, `CaptureGamut`, or a Panasonic make or model |
| `sony` | `Item name="tag" value="word"` | `CaptureGammaEquation`, or a Sony make or model item |
| `exif-panasonic` | ExifTool `Make` and `Model` only | the same Panasonic patterns, and no colour tag |
| `exif-sony` | ExifTool `Make` and `Model` only | the same Sony patterns, and no colour tag |

The Panasonic rule may open a same-name sidecar only when it already matched and `CaptureGamma` is empty. The Sony rule does not open a sidecar. ExifTool is never asked for a colour tag.

The Sony attribute order is `name-value`. That is the FX6 shape. `either` is in the grammar so a later body can use it. No rule uses it yet.

An FS5 or FS7 MXF does not carry that XML line. The same tag is a SMPTE label in the header. `mediapipeline-detect` reads it with ExifTool `-u -fast -CaptureGammaEquation` when the XML grep missed. The label read on both bodies, `060e2b34.0401.0101.04010101.01020000`, is written as `rec709`. A label that is not that value is copied as ExifTool printed it.

## Not in the file

SmallSony, phone, DJI, and Insta360 are not rules. No gamma word has been read from those files. The model `FDR-AX53` and the model `iPhone 17 Pro Max` are in their files, and neither stores a gamma word. The A7 word `rec709` and the FS5/FS7 label above are the same card word. What the encoder does with `rec709` is `gamma.rec709` in `pipe.conf`.
