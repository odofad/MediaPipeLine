# House archive

From the Painteddog.tv archival policy. Detection does not read these names. The encoder is not built, so the CRF numbers are not in `pipe.conf`.

A raw clip is named:

```text
Year_Month_Day_Place_Persons_Content_CameraModel_ClipNumber_OptionalSubInfo
2020_11_27_Boston_WiumBrent_NgatiLionPride_FS5_01_SingleFemaleWithMale
```

The camera model sits before the clip number. Optional sub-info can follow the number, so the last field is not the camera. The folder name is a separate habit. The archivist ends that with the camera. v1 does not read either word.

The transcode is HEVC in an MP4, same name, new extension. The policy's size check is 30–50% of the camera original. High movement is allowed to land higher. The CRF is a camera class, not a gamma:

| Class | CRF |
| --- | --- |
| FS cameras | 14 |
| 1080p cameras | 22 |
| Drone | 26 |
| HVR | 27 |
| GoPro | 27 |

Originals go to the Archival folder with no extra sorting. HEVC goes to `HEVC_Archives / Country / Place / Year / Folder_of_content`. Nothing stays in Incoming more than 3 days. Camera originals move to cold storage after 3 months.
