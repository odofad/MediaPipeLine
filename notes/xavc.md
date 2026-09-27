# Sony XAVC, from opened files

Opened on 2026-09-27. ExifTool 13.59. The AX53 card was a full SD dump. The FS5 file was one MXF. The A7RIII file was one MP4. Detection still does not read a container colour tag.

XAVC writes the picture in two shapes. The consumer and stills bodies use an MP4 and an XML device tag. The FS5 uses an MXF and three SMPTE labels in the picture descriptor. They are not the same text, and a reader for one misses the other.

## XAVC-S, FDR-AX53

The card root is `PRIVATE/M4ROOT/CLIP/`. The brand in `ftyp` is `XAVC`. The picture is in `mdat`. `moov` is after the picture, and a `meta` atom after that holds the NonRealTimeMeta XML. The same XML is copied to a sidecar named `C0001M01.XML`, not `C0001.XML`. Detection does not open a Sony sidecar, and that stem would not match anyway.

The XML on `C0001.MP4`, `C0002.MP4`, and `C0003.MP4` is:

```xml
<Device manufacturer="Sony" modelName="FDR-AX53" serialNo="4294967295"/>
```

`4294967295` is the empty serial. There is no `Item name="CaptureGammaEquation"` and no `CaptureGamma`. The model string is not in the first 2 MB. It is only in that `meta` atom.

`C0001` and `C0003` have no container colour tags. `C0002` is the 4K clip. Its h264 stream says primaries `bt709` and transfer `iec61966-2-4`, which is xvYCC. That flag is not a gamma word. Detection does not read it.

Picture and audio on the three MP4s: `h264`, and `pcm_s16be` stereo. The short `AVCHD/BDMV/STREAM/00000.MTS` is a different recording: `h264`, AC-3 5.1, and no model string anywhere in the file. Known cameras cannot name that file.

`FDR-AX53` is a block in `known-cameras.conf`: `rec709` and `rec709`. Detection reads `modelName` from the `Device` tag and uses that block only because the clip has no gamma word. A word already in the file is kept. Both real AX53 clips card as `Sony` / `rec709` / `rec709` and stay in `2.Logged` once the file name starts with a date. A folder that only contains `PRIVATE/` is not walked. The pass logs `no-media` and leaves it.

## XAVC-S, ILCE-7RM3

File: `2026_08_20_Bazel_GarethSettingUpSolarisTrapCameraShotFilm_A7riii_01_CableTyingCameraTrap_01.MP4`. The name already starts with a date. Same container as the AX53: brand `XAVC`, picture in `mdat`, NonRealTimeMeta in the trailing `meta` atom. No sidecar was in the archive.

Picture: h264 High, 1920×1080, 50 fps, progressive, 6.72 s, `yuvj420p` full range. The h264 stream has no transfer or primaries tag. Audio is `pcm_s16be` stereo. The timed-metadata track says timecode `02:00:28:16`.

The XML has both the device tag and the camera-unit items:

```xml
<Device manufacturer="Sony" modelName="ILCE-7RM3" serialNo="4294967295"/>
<Item name="CaptureGammaEquation" value="s-log3-cine"/>
<Item name="CaptureColorPrimaries" value="s-gamut3-cine"/>
<Item name="CodingEquations" value="rec709"/>
```

`ILCE-7RM3` is not in `known-cameras.conf`. This body can shoot more than one picture, so it must not be added. The equation stands: `s-log3-cine` and `s-gamut3-cine`. Both already have treatments (`s-log3` and `s-gamut3-cine`), so the shoot stays in `2.Logged`. `CodingEquations` is the matrix, the same job as the FS5 `ColorimetryCode`. The grep does not read it. `rec709` there is not the gamma.

`exiftool -CaptureGammaEquation` prints nothing on this MP4. ExifTool splits the items into `AcquisitionRecordGroupItemName` and `AcquisitionRecordGroupItemValue`. The byte grep for `Item name="CaptureGammaEquation"` is what sees the word. The MXF label command would miss it.

## XAVC MXF, PXW-FS5

File: `2026_07_08_TCC_Ntiyiso_BlydevalleiFarm_Gareth_Day1_CameraTrapInstallation_01.MXF`. The name already starts with a date.

| | |
| --- | --- |
| Picture | h264 High, 3840×2160, 25 fps, progressive, 6.72 s |
| Audio | four mono `pcm_s24le` streams, 48 kHz |
| Timecode | `00:00:00:00` |
| Data | one `vbi_vanc_smpte_436M` track |

The header names the writer, not the camera. ExifTool prints:

| Tag | Value |
| --- | --- |
| `ApplicationSupplierName` | `Sony` |
| `ApplicationName` | `Mem` |
| `ApplicationVersionString` | `2.00` |

`Mem` is the XAVC SDK name. FS5 and FS7 both write it, so it is not a `known-cameras.conf` block. There is no `Make`, `Model`, `DeviceModelName`, or `CameraModelName`. A search of the whole file, both byte orders, finds no `PXW`, `FS5`, `S-Log`, or `S-Gamut`.

RDD 32 puts the AVC picture, AES3 audio, and ANC into an OP-1a MXF. The colour words live in the picture descriptor, which is the same three optional items RDD 18 defines for the camera unit. On this clip:

| Local tag | ExifTool | Bytes | Meaning |
| --- | --- | --- | --- |
| `0x3210` | `CaptureGammaEquation` | `060e2b34.0401.0101.04010101.01020000` | BT.709 transfer |
| `0x3219` | `ColorPrimaries` | `060e2b34.0401.0106.04010101.03030000` | BT.709 primaries |
| `0x321A` | `ColorimetryCode` | `060e2b34.0401.0101.04010101.02020000` | BT.709 matrix |

The command detection runs for the gamma is `exiftool -u -fast -m -s3 -CaptureGammaEquation`. On this file it prints the first label, and the script writes `rec709`. `-fast` is enough. The label is in the header. When that word is set, detection also runs `exiftool -u -fast -m -s3 -b -ColorPrimaries`. Those 16 bytes are the public BT.709 primaries, and the script writes `rec709`. A different value is left empty. `ColorimetryCode` is not read. A private acquisition label is not read. MediaTrace is not read.

ExifTool does not name the other two. Without `-b` they print as "Binary data 16 bytes". There is no `CaptureColorPrimaries` tag. Black reference is 16 and white is 235, so the range is limited. Detection still writes `range: unknown`.

The `0x8001`–`0x800e` items are the AVC sub-descriptor, not a camera and not a colour. The values that identify this stream are progressive, GOP 12, 2 B-frames, max bitrate 99,999,744, High profile (100), level 5.1, sequence-parameter flag `0x30`.

RDD 18 can also ride in the ANC track, per frame. This file has that track and still has no camera word in it. The three header labels are the whole story.

## MediaInfo

Camscan's colour line is `mediainfo --ParseSpeed=0` and it is not a camera word. On these files:

| File | Colour line |
| --- | --- |
| A7RIII | `AVC\|8\|\|\|\|Full\|` |
| FS5 | `AVC\|8\|BT.709\|BT.709\|BT.709\|Limited\|` |
| AX53 `C0001`, `C0003`, and the `.MTS` | `AVC\|8\|\|\|\|\|` |
| AX53 `C0002` | `AVC\|8\|xvYCC\|BT.709\|BT.709\|Limited\|` |

The A7 video line has a full range and no transfer, primaries, or matrix. The words `s-log3-cine` and `s-gamut3-cine` are not in that line. The real-time metadata block does print a first frame: transfer `0E06040101010605` (not translated), primaries `BT.709`, matrix `BT.709`. That primaries line disagrees with `CaptureColorPrimaries` `s-gamut3-cine`. The XML is the camera word. The FS5 line does match the three header labels, and MediaInfo names them `BT.709`. `xvYCC` on the AX53 4K clip is the container flag detection already ignores.

## MediaTrace

`mediainfo --Details=1 --ParseSpeed=0` dumps the header blocks and does not walk the picture. The colour line hides the label bytes. The trace shows them.

The A7 real-time track is a Camera Unit Acquisition Metadata set. The three local tags are the same numbers as the FS5 picture descriptor. The first two values are Sony private labels. MediaInfo does not translate them.

| Tag | A7 real-time label | What MediaInfo calls it |
| --- | --- | --- |
| `0x3210` | `06.0E.2B.34.04.01.01.06.0E.06.04.01.01.01.06.05` | nothing. Organization is Sony |
| `0x3219` | `06.0E.2B.34.04.01.01.06.0E.06.04.01.01.03.01.05` | `BT.709`. The bytes are not the public BT.709 primaries label |
| `0x321A` | `06.0E.2B.34.04.01.01.01.04.01.01.01.02.02.00.00` | `BT.709` coding equations. This one is the public label |

The XML on the same file says `s-log3-cine`, `s-gamut3-cine`, and `rec709`. The `rec709` matches `0x321A`. The other two XML words are not the names MediaInfo printed. The `xml ` atom is 1449 bytes and the trace leaves that payload as unknown. The byte grep is still what reads the words.

The private labels are readable. A real-time decoder table names these two, and on this A7 file they match the XML:

| Tag | Label | Name |
| --- | --- | --- |
| `0x3210` | `060E2B34.0401.0106.0E06.0401.0101.0605` | `S-Log3-Cine` |
| `0x3219` | `060E2B34.0401.0106.0E06.0401.0103.0105` | `S-Gamut3.Cine` |

MediaInfo's `BT.709` title on `0x3219` is wrong. Those bytes are not the public primaries label. `0x321A` is the public BT.709 coding-equations label, and the XML `rec709` agrees.

The FS5 header uses the public BT.709 labels, which the trace names. Its ANC transfer label is the same private family with the last byte `01` (`060E2B34.0401.0106.0E06.0401.0101.0601`). That value is not in the table. Detection still copies the XML word, or the public header label. It does not copy a private label.

The detector does not read MediaTrace. The XML payload, which is the camera word on the A7 and the AX53, is left as unknown. The private primaries label is titled `BT.709`, and the bytes are `S-Gamut3.Cine`. A reader of those titles would write the wrong gamut. The byte grep and the public header label stay the readers.





## What detection does with the FS5

`Mem` does not match `known-cameras.conf`, so the database does not replace the equation. The card is `camera: Sony`, `gamma: rec709`, `gamut: unknown`, `codec: h264`, and `audio: pcm_s24le x 1` four times. `gamma.rec709` is `rec709-as-is`. `gamut.unknown` is not a treatment. The shoot goes to `2.3.Error` because the primaries label is never read.
