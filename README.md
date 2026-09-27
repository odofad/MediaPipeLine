# MediaPipeLine

Master copy for the media pipeline. Detection, encoding, and the other pipeline scripts live here. This tree is the copy you edit.

On the server it belongs at `/opt/MediaPipeLine`, on the pool, so a reinstall of Ubuntu does not take it with it.

```text
MediaPipeLine/
  install.sh     copies this tree into the system locations
  pipe.conf      shipped defaults for paths, tunables, and extensions
  camera-rules.conf  where a camera writes its gamma word. Version 1.
  bin/           scripts. Installed to /usr/local/bin
  systemd/       units and timers. Installed to /etc/systemd/system
  notes/         the script plan and the probe notes
  CHANGELOG.md   what changed, newest first
```

`camera-rules.conf` is the camera rule list. The grammar is fixed at version 1. `mediapipeline-camera-rules` checks that file and does not probe a clip. Detection does not read the file yet. A treatment stays in `pipe.conf`.

`bin/mediapipeline-detect` is the detection pass. `systemd/` holds its timer. `install.sh` asks whether to enable that timer. The timer runs as the user you name. Press enter and it uses the user who ran `sudo`. 

`bin/mediapipeline-status` is the SSH screen. It prints the timer, whether a pass is running, then Logging (`unprocessed`, `completed`, `failed`, `relog`) and Encoder (`queue`, `completed`, `failed`). `mediapipeline-status -f` redraws every 2 seconds. The encoder stays `not installed` until that service exists. An encoder log, when it exists, is `/var/log/mediapipeline/encode.log`.

```bash
sudo /opt/MediaPipeLine/install.sh
```

`install.sh` installs `pipe.conf` to `/etc/mediapipeline/pipe.conf` only when that file does not exist yet. Every install refreshes `/etc/mediapipeline/pipe.conf.default`. It then asks for two roots. The archive root is the input. It creates `2.Logged`, `2.1.Relog`, `2.2.Recovery`, `2.3.Error`, `3.Convert`, and `4.Converted` under it. The encode output is the folder the encoder will write. Nothing encodes yet. Those seven paths are written into the live conf. Gamma, copyright, and the other keys are left alone. Press enter to keep the path already in the conf.

Edit a script here, then install. Edit tunables in `/etc/mediapipeline/pipe.conf`, not in the shipped copy, or the next machine will not see the change until you copy it back.

```bash
sudo /opt/MediaPipeLine/install.sh
```

That replaces `/usr/local/bin` and `/etc/systemd/system` with the current `bin/` and `systemd/` files. A script removed from `bin/` is removed from `/usr/local/bin` on the next install. The installed script, `/etc/mediapipeline`, the log directory, and the folders just created are owned by the chosen user. The systemd unit files stay owned by root. Answering no to the timer leaves an already enabled timer as it is.

Do not edit the copies under `/usr/local/bin`. The next install overwrites them.
