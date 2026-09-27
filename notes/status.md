# mediapipeline-status

One screen over SSH. It does not change a folder or a card.

```bash
mediapipeline-status
mediapipeline-status -f
```

The first form prints once. `-f` redraws every 2 seconds until ctrl-c. That redraw is the live error feed. A finished card is not a line in it. The lines are the ones `mediapipeline-detect` appends to `/var/log/mediapipeline/detect.log`.

The timer line is enabled or not, the last run, and the next run. The pass is `running`, `idle`, or `failed`. `failed` is the last systemd result, not a new log line. The folder counts are the direct children. `2.Logged` and `2.3.Error` also name the newest shoot. `encode out` counts files as well as folders, because that is where the encoder will write.

GPU is one line from `nvidia-smi`: name, use, memory, temperature. No `nvidia-smi` prints that, and does not fail the screen.

Encoder is `not installed` until `mediapipeline-encode.service` exists. When `/var/log/mediapipeline/encode.log` exists, its last lines are printed under the encoder. Nothing writes that file yet.
