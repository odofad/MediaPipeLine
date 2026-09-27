# Gamma and gamut table

Detection copies the camera's word onto the card. It does not rename `HD` to Rec.709. The encoder does not open the camera file. It looks the card word up in `pipe.conf`.

The key is the exact card text, including capitals. `gamma.HD` matches a card line `gamma: HD`. It does not match `hd`. The value is the treatment.

| Card gamma | What wrote it | Treatment |
| --- | --- | --- |
| `HD` | Panasonic `CaptureGamma`, with `BT.709` on the CX350 probe | `rec709-as-is` |
| `V-Log` | Panasonic `CaptureGamma` | `v-log` |
| `V-LogL` | Panasonic `CaptureGamma` on a GH-series body | `v-log` |
| `HLG` | Panasonic `CaptureGamma` | `hlg` |
| `s-log3-cine` | Sony `CaptureGammaEquation`, with `s-gamut3-cine` on the FX6 probe | `s-log3` |
| `rec709` | Sony `CaptureGammaEquation`, and the `FDR-AX53` line in `known-cameras.conf` | `rec709-as-is` |
| `Log3G10` | RED Gamma Curve, with `REDWideGamutRGB` on the reference clip | `log3g10` |

`rec709-as-is` means the picture is already HD. The encoder does not run a log conversion. The other treatments are names only. No filter or LUT is chosen for them yet.

A word that is not in the table is not encoded. `unknown` on the card is not in the table. If detection reads a real gamma or gamut that has no line, it appends one to the live `/etc/mediapipeline/pipe.conf`:

```text
gamma.CINE-D = unknown
```

It does that once. A second pass does not add the line again, and it does not change a treatment you have already set. The folder is then moved to `2.3.Error`, card and all. Change `unknown` to the treatment, then move the folder back to `2.Logged`. Detection does not watch the error folder. The encoder skips a value of `unknown`. Copy that line back to the `pipe.conf` in this tree if the next machine should have it. A treatment other than `rec709-as-is` also needs the card's gamut listed. The gamut keys already defined are `BT.709`, `V-Gamut`, `s-gamut3-cine`, and `REDWideGamutRGB`.
