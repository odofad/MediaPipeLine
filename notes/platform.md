# Platform

Ubuntu Server 26.04 is the only system this tree is built for. `ID=ubuntu` and `VERSION_ID=26.04` in `/etc/os-release`. A desktop install of the same release is the same packages. Another Ubuntu release is not a target.

## System binaries

When Ubuntu ships the tool, the script runs `/usr/bin/<name>`. A copy in `/usr/local/bin`, `/usr/local/lib`, or `/usr/lib/jellyfin-ffmpeg` does not win.

The conf stores the name, not a path. `ffmpeg`, `ffprobe`, and `exiftool` are replaced with the file in `/usr/bin` when that file exists. A live conf that still says `/usr/lib/jellyfin-ffmpeg/ffmpeg` is ignored for that reason.

| Command | Package | Path |
| --- | --- | --- |
| `ffmpeg`, `ffprobe` | `ffmpeg` | `/usr/bin/ffmpeg`, `/usr/bin/ffprobe` |
| `exiftool` | `libimage-exiftool-perl` | `/usr/bin/exiftool` |
| `mediainfo` | `mediainfo` | `/usr/bin/mediainfo` |
| `timeout` | `coreutils` | `/usr/bin/timeout` |
| `iconv` | `libc-bin` | `/usr/bin/iconv` |
| `systemctl` | `systemd` | `/usr/bin/systemctl` |

`nvidia-smi` is optional and only for the status screen. The installer does not install it. When `/usr/bin/nvidia-smi` exists, that is the one that runs. A missing one prints `no nvidia-smi` and the screen continues.

Do not build these tools. Do not put a second copy of their libraries in `/usr/local/lib`. The linker searches that directory first. An old `libmpg123.so.0` there hid Ubuntu's `libmpg123-0t64` and every `ffprobe` died with `undefined symbol: mpg123_info2`. `dpkg` does not own `/usr/local`, so an upgrade will not remove that file.

`command -v` is not a proof that the tool works. The name can resolve, and the dynamic linker can still kill the process. The test is to run it.

## Exceptions

`REDline` is not an Ubuntu package. The conf names it `REDline`. The script looks that name up on `PATH` and does not rewrite it to `/usr/bin`. A missing binary does not stop a pass. A `.r3d` is then gamma `unknown`, and that shoot goes to Error. Other cameras are read. `install.sh` warns at the end and still exits 0. Install the binary by hand on a machine that logs RED.

Jellyfin's ffmpeg is not an Ubuntu package. It is not an exception this pipeline uses. Do not add `repo.jellyfin.org`. Ubuntu 26.04's `ffmpeg` package is 8.0.1. That is the encoder binary when the encoder is written. If a later treatment needs a filter that package does not have, that is a new exception, written here first, the same way `REDline` is.

## Our own scripts

`install.sh` copies the scripts in `bin/` to `/usr/local/bin`. Those programs are not Ubuntu packages. The systemd unit starts `/usr/local/bin/mediapipeline-detect`. That path stays. Do not install them under `/usr/bin`.

## New installer

`install.sh` copies the scripts, installs the timer unit, asks for the archive root and the encode output, and warns when `REDline` is missing. It also does the following:

1. Stop unless `/etc/os-release` says Ubuntu 26.04.
2. `apt-get install` `ffmpeg`, `libimage-exiftool-perl`, and `mediainfo`.
3. Run `/usr/bin/ffprobe -version`, `/usr/bin/exiftool -ver`, and `/usr/bin/mediainfo --Version`. Any failure stops the install. `command -v` is not the test.
4. On a new conf, write `ffmpeg = ffmpeg`, `ffprobe = ffprobe`, `exiftool = exiftool`, and `mediainfo = mediainfo`. A later install still does not overwrite a live conf. It only refreshes `pipe.conf.default` and the folder paths it asks for.
5. Warn when `REDline` is not on `PATH`. Do not fail the install for that.
6. Do not add Jellyfin's repository, do not install the NVIDIA driver, and do not copy a library into `/usr/local`.

A later install still does not overwrite a live conf. A live conf without a `mediainfo` line still runs. Camscan uses the name `mediainfo` and says so.

## Review

Read on 2026-09-27 against the rules above.

| Script | Result |
| --- | --- |
| `mediapipeline-detect` | `ffprobe` and `exiftool` go to `/usr/bin` when those files exist. `REDline` stays a `PATH` lookup. A missing `REDline` logs `redline-missing` and the pass continues. |
| `mediapipeline-camscan` | The same two tools, plus `/usr/bin/timeout`, `/usr/bin/iconv`, and `/usr/bin/mediainfo` when those files exist. A missing `REDline` writes `not found` and the report is still written. MediaInfo is evidence. Detection does not read it. |
| `mediapipeline-status` | `/usr/bin/systemctl` and `/usr/bin/nvidia-smi` when those files exist. No `nvidia-smi` does not fail the screen. |
| `mediapipeline-camera-rules` | No external binary. It checks the rule file only. |
| `install.sh` | Stops unless the machine is Ubuntu 26.04. Installs `ffmpeg`, `libimage-exiftool-perl`, and `mediainfo`. Stops if `/usr/bin/ffprobe`, `/usr/bin/exiftool`, or `/usr/bin/mediainfo` does not start. Warns when `REDline` is missing and still exits 0. |

The unit file starts `/usr/local/bin/mediapipeline-detect`. That is the right path for this project's own scripts.
