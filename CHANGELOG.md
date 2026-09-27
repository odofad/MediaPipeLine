# Changelog

Newest first.

## 2026-09-27 — status screen

`mediapipeline-status` no longer lists the archive folders by directory name. It reports the logging pass and the encoder as three states each.

Logging:

- `unprocessed` is a shoot still in `2.Logged` with no mag card.
- `completed` is a shoot still in `2.Logged` with a mag card. The colour was resolved. Detection does not move it to `3.Convert`.
- `failed` is `2.3.Error`. Unknown gamma or gamut put the whole shoot there, card included.
- `relog` is `2.1.Relog`. The folder name, or a media filename, does not start with a real `YYYY_MM_DD_`. That is a mistake from the logging step before detection. The shoot is not probed. A person fixes the names and moves it back to `2.Logged`.
- `recovery` is printed only when `2.2.Recovery` is not empty.

Encoder:

- `queue` is `3.Convert`.
- `completed` is `4.Converted`.
- `failed` is `0`. There is no encode-failure folder yet.
- The heading stays `not installed` until `mediapipeline-encode.service` exists.

The encode output path is not listed. It is a tree of finished files, not a count of jobs. The card name is `card_suffix` from `pipe.conf`. An empty suffix is `.mag.txt`.

`notes/status.md` and the status paragraph in `README.md` match this screen.
