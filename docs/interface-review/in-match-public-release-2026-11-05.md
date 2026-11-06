# In-match public release · 2026-11-05

The game changes in [PR #115](https://github.com/danybgoode/aomx/pull/115) merged as `e60fb1c61a4e`. Both public builds were exported from that exact commit with game version `godot-4.7.2-skirmish-12`, content version `la-roma-world-6`, and the same simulation hash as the new match host. The home screen was reviewed but not changed by this slice. The earlier bilingual landing work from PR #114 was already present in the merged source.

| Public channel | Butler build | Source ZIP SHA-256 | State |
| --- | --- | --- | --- |
| `danybgoode/battle-for-la-roma-play:html5-public` | `#2309749` | `79cb1c6a9304348b557bf1938e56b76edb70edca9f71e0784f1986264d965be4` | Ready, `public-e60fb1c61a4e` |
| `danybgoode/battle-for-la-roma-play:mac-public` | `#2309750` | `b49b20caef62db055036eb9fd7cc7c7f8d9b51bd8c0f58632a479481150138dd` | Ready, `public-e60fb1c61a4e` |

The fetched files on both channels matched every file in the local exports. The fetched macOS app passed `codesign --verify --deep --strict` and a bounded headless startup. The anonymous [public game page](https://danybgoode.itch.io/battle-for-la-roma-play) returned HTTP 200. A headless Chrome session opened a match from the fetched public Web package at 1907×931. The release export's headless smoke passed campaign, Wonder, team mode, five maps and public room setup.

The CI-built ARM64 match image `ghcr.io/danybgoode/aomx-match:e60fb1c` is healthy on the public host; ingest remains healthy at `5baa01b`. Backup and disposable restore jobs completed successfully before the image switch. The live HTTPS health check returned 200; the exact itch Web origin preflight returned 204 and a foreign origin returned 403. CI project checks and CodeQL passed. Golden Frijoles roadmap push reported artifact version 89.

The owner and two uncoached interface tasks remain open under the interface epic. A full match from a downloaded public build, physical phone check and two-human room play were not performed in this release check. Public play events are not sent, so no first-match completion baseline is claimed.
