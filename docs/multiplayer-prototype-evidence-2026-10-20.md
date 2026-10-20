# Private-match prototype evidence — 2026-10-20

The merged prototype uses Godot 4.7.2 with a Node HTTP host and one Godot authority worker. This is the local pre-deployment snapshot. The later [Restricted-host QA record](multiplayer-remote-qa-2026-10-20.md) supersedes its host and remote-smoke gaps; the downloadable build and owner walkthrough still need separate acceptance.

| Check | Observed result | Limit |
| --- | --- | --- |
| Node suite | 31/31 against disposable Postgres 17, including 30-day expiry and withdrawal | Local and CI checks; no live deletion request yet |
| Two local native clients | Opposite invited slots, one accepted order, duplicate acknowledgement, cross-slot denial, rotated reconnect token, fogged state | Same macOS host and loopback; no terminal through UI |
| Terminal replay | Godot two-side order stream reached tick 1016, verified final hash and corruption/version errors; HTTP delivered 103 frames per participant with enemy private fields redacted; two native Godot replay clients opened their own frame | Generated recording, not a real remote match |
| Authority worker | macOS arm64, La Roma, Regios/Poblanos, seed 1, four starting entities, four resources, fog, 1,000 ticks: mean 7.024 ms, p95 9.110 ms, max 30.964 ms per tick request; 136,592 KiB RSS; side views 2,158/2,354 B; final hash `4d6266cbe25b249d14570136fecc20961863f33338e20a0d7f02021b80844905` | Request time includes loopback IPC/serialization; no burst or packet impairment |
| Linux image | Pinned amd64 Godot 4.7.2 produced same 1,000-tick hash and passed init/tick as nonroot with read-only root, 64 MiB tmpfs, 768 MiB memory, 0.75 CPU, PID/cap limits | Docker Desktop emulation on the same Mac, not a native Linux player |
| ARM64 image | Official checksum-verified Godot 4.7.2 ARM64 binary in a capped Docker image produced the same 1,000-tick hash locally | Docker Desktop on the same Mac; VM native check and remote match still owed |
| Web | Godot Web export completed locally | No browser join or playable Web client demonstrated |
| Host preflight | Oracle VM has 8,584 MiB available memory and 30 GiB available disk; Caddy 2 validated the proposed restricted route | Existing VM containers remain unchanged; no match service deployed |
| Independent review | Security/integrity reviewer found and rechecked fixes for replay fog, rejected side-1 mutation, terminal rejoin, version hashes, rate limits and worker lifecycle; no remaining concrete code blocker | Release acceptance still needs measurements and actual remote smoke |

Reproduce the local checks with `npm test`, `GODOT_BIN=/path/to/Godot npm run multiplayer:integration`, `GODOT_BIN=/path/to/Godot npm run multiplayer:replay-integration`, and `GODOT_BIN=/path/to/Godot npm run multiplayer:benchmark`. The Docker read-only worker gate is in `.github/workflows/alpha-ci.yml`.

## Acceptance owed at the local prototype boundary

The representative large-army, cross-device baseline/100 ms/150 ms RTT and 1% loss matrix has no measurements. Native Linux and Web clients have not joined. The Oracle VM, TLS route, distinct live codes, signed Restricted download, full match, reconnect/expiry and replay have not been exercised together. A disposable VM backup restore passed on 2026-10-20; the owner supplied the support contact and 30-day live retention policy, now covered by PR #57. No observed retention cohort or later-day completion baseline exists.
