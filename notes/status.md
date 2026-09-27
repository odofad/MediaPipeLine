# mediapipeline-status

One screen over SSH. It does not change a folder or a card.

```bash
mediapipeline-status
mediapipeline-status -f
```

The first form prints once. `-f` redraws every 2 seconds until ctrl-c. That redraw is the live error feed. A finished card is not a line in it. The lines are the ones `mediapipeline-detect` appends to `/var/log/mediapipeline/detect.log`.

The timer line is enabled or not, the last run, and the next run. The pass is `running`, `idle`, or `failed`. `failed` on that line is the last systemd result, not a new log line.

Logging is the detection pass:

- `unprocessed` is a shoot still in `2.Logged` with no `.mag.txt`.
- `completed` is a shoot still in `2.Logged` whose card was written and whose colour was resolved. Detection does not move it to `3.Convert`.
- `failed` is `2.3.Error`. Unknown gamma or gamut put the whole shoot there, card included.
- `relog` is `2.1.Relog`. The folder name, or a media filename, does not start with a real `YYYY_MM_DD_`. That is a mistake from the logging step before detection. The shoot is not probed. A person fixes the names and moves it back to `2.Logged`.
- `recovery` is printed only when `2.2.Recovery` is not empty.

Encoder is `not installed` until `mediapipeline-encode.service` exists. Under it:

- `queue` is `3.Convert`.
- `completed` is `4.Converted`.
- `failed` is `0`. There is no encode-failure folder yet.

The encode output path is not a job count, so it is not listed. GPU is one line from `nvidia-smi`: name, use, memory, temperature. No `nvidia-smi` prints that, and does not fail the screen. When `/var/log/mediapipeline/encode.log` exists, its last lines are printed under the encoder. Nothing writes that file yet.
