# Unified public Web and macOS release — 2026-11-05

## Source and scope

The six previously stacked PRs #99 and #102–#106 were combined with the existing public solo branch by [PR #111](https://github.com/danybgoode/aomx/pull/111). Public player-created private rooms followed in [PR #112](https://github.com/danybgoode/aomx/pull/112). Both merged with passing CI. The released source commit is `f1000b4b07b8` (`godot-4.7.2-skirmish-12`, `la-roma-world-6`).

Both public builds include the home screen, four factions, five solo maps, three campaign chapters, Wonder on every solo map, renewable food fields, separated small-map resources, solo 2 v 2, portable same-version solo saves, touch controls, audio, and player-created private online rooms. The room host accepts one creator and one friend per high-entropy code. Historical Restricted QA channels remain private; the public itch page has exactly one browser channel and one macOS download channel.

## Published artifacts

| Channel | Butler build | Source archive SHA-256 | Verification |
| --- | --- | --- | --- |
| `danybgoode/battle-for-la-roma-play:html5-public` | `#2307473` | `b90ecead3d6fdb3ff9f209103ba3e71c364233f70fedbb08d7202896d0abc11e` | Ready; all nine fetched files matched the source ZIP extraction |
| `danybgoode/battle-for-la-roma-play:mac-public` | `#2307479` | `cb7c2a40834ecd5dea430df528fed46667d0a0f6962acf51d5d18d5c0e738f2a` | Ready; all seven fetched files matched the source ZIP extraction; strict deep code-signature verification passed |

Both channels report version `public-f1000b4b07b8` in Butler. Their source manifest is `dist/public/public-f1000b4b07b8.json` (ignored local release artifact). The anonymous [itch page](https://danybgoode.itch.io/battle-for-la-roma-play) returned HTTP 200, and the owner-visible page showed the matching version, the browser Run game control and the macOS download. Its description and install instructions were updated to describe the released modes, room codes, save compatibility and the correct `Battle for La Roma.app` name.

## Host and checks

ARM64 image `ghcr.io/danybgoode/aomx-match:f1000b4` is healthy on the Oracle host. `AOMX_PUBLIC_ROOMS_ENABLED=1` is set server-side. The exact Web origin is `https://html-classic.itch.zone`; the client bundles only the public HTTPS match origin `https://alpha-api.159.54.158.4.sslip.io`, version and simulation hash. The existing operator-invite route remains gated by its separate flag.

The live HTTPS check returned 200 for room creation and second-player join, then `playing` with a scoped side view. A foreign Web origin returned 403. CI passed Node, Godot, native two-client room integration, and the existing replay/contract suites. The final export smoke confirmed five maps, campaign, Wonder, solo 2 v 2 and public room controls in the built project. The host's backup, retention, health and restore-drill timers were active at release time.

## Open evidence

The project's `smoke` skill could not run a rendered browser check because this repository has no `scripts/live-smoke.mjs`, `live-smoke.config.json` or Playwright harness. A full match from a freshly downloaded public Web or macOS build, online replay from that download, physical phone support, and two-human social play remain unverified. Public builds send no play events, so the agreed North Star has no observed baseline. Version-7 saves and replays remain on device but version 12 cannot resume them; the itch page explains this. An interrupted room host ends active matches without a result.
