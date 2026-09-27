# Detection trigger

A folder arriving in `2.Logged` does not start detection. There is no inotify watch. The starter is `systemd/mediapipeline-detect.timer`. It runs `mediapipeline-detect.service`, which is one pass of `/usr/local/bin/mediapipeline-detect`.

| | |
| --- | --- |
| First run after boot | 2 minutes |
| Run again | 5 minutes after the previous pass started |
| Late, if the machine was off | As soon as the timer is loaded (`Persistent=true`) |
| Manual | `systemctl start mediapipeline-detect.service` |

The 5 minutes stays longer than `settle_seconds` (120). A copy that is still being written is skipped by the pass, and the next pass cards it once it has been quiet. systemd does not read `pipe.conf`, so the 5 minutes lives in the timer unit. Changing it means editing `mediapipeline-detect.timer` and running `install.sh` again. Do not raise `settle_seconds` above 5 minutes without changing the timer too.

The service waits until the `logged` path chosen at install is on a mounted filesystem, so a pass does not run before the ZFS pool is imported.

If a pass is still inside `REDline` when the next tick is due, systemd queues another start. The script takes `lock_file` with a non-blocking lock and exits 0 when that lock is already held. The queued start does not wait and does not scan.

`install.sh` copies the units. It asks which user the service runs as, and whether to enable the timer. The user who ran `sudo` is the default. Answering no leaves an already enabled timer as it is. The service waits until the `logged` folder from the install answers is on a mounted filesystem.
