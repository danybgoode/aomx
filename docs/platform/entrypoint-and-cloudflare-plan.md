# Game entrypoint and Cloudflare cutover

Reviewed against the current `oracle-edge` checkout on 2026-11-04. This is a release sequence, not a DNS change or a claim that the new game build is online.

## Current state

- `oracle-edge/sites/aomx.caddy` serves only `alpha-api.159.54.158.4.sslip.io`. The `/v1/match/*` path reaches the one-room private-match service; other routes remain on the operator allowlist. The new shared Caddy configuration trusts `CF-Connecting-IP` only from published Cloudflare ranges, so the operator matcher can use the real visitor IP after proxying.
- aomx still uses its own `aomx_proxy` network and has its Caddy site file in `oracle-edge`; it has not adopted the full tenant site-install contract. The shared VM has 2 OCPU / 12 GB, CI-built images, aomx container caps, encrypted nightly env backup, and weekly restore drill. A Caddy reload affects every tenant.
- `oracle-edge/ops/provision.sh` deliberately leaves 80/443 reachable from anywhere because at least one site still needs ACME HTTP-01. Changing the VM security list for aomx alone would change the certificate path for other products.
- The owner-private [Battle for La Roma entry page](https://battle-for-la-roma-private-pilot.jokeyquail1.chatgpt.site) is a separate static Site. It links to the Restricted itch.io Web and macOS pilots. It is not on `battleforlaroma.com` and does not serve the new game ZIP.

## Sequence for an approved tester cutover

1. Merge a reviewed rules/client stack, build the arm64 private-match image in CI, and deploy the matching game version to the aomx tenant using its pinned commit and health/rollback script. Confirm VM headroom and the existing restore drill first. Keep private admissions off until the bounded smoke.
2. Choose an owned game domain and an exact Restricted Web origin. In `oracle-edge`, add an explicitly named aomx Caddy site for `alpha-api.<owned-domain>` with working origin TLS under Cloudflare Full (strict). Follow the other tenants' Authenticated Origin Pulls pattern only after its cert and trust path are verified. Validate the full Caddy config and reload through `ops/deploy-edge.sh`; check the sslip route still works during migration.
3. Add a proxied Cloudflare DNS record pointing that named API host at `159.54.158.4`. Confirm HTTPS health, operator-only ingest rejection, an allowed operator path, match admission off, and that a direct request cannot spoof `CF-Connecting-IP`.
4. Set `AOMX_MATCH_WEB_ORIGIN` to the exact Restricted Web launch origin, not a wildcard. Check allowed and rejected preflights on the real route. Export clean Web and macOS builds with the new HTTPS API/ingest origin and the matching simulation hash. Upload to Restricted tester channels only after signed/served build checks; run one invited Web/native terminal match with separate codes, then turn admission off, restart the match process and verify a fresh join is denied.
5. Retire `sslip.io` only after every active tester has a new build and the new origin has passed the owner walkthrough. Restricting 80/443 to Cloudflare is a separate shared-host change: first inventory and migrate every tenant's certificate renewal path, then update OCI ingress with rollback and monitor all sites. It should not be coupled to aomx DNS alone.

A future public `battleforlaroma.com` page can point to an approved Web build or serve one at a game subdomain. The domain, access audience, and game-hosting decision belong to the owner; the current private page is a reviewable prototype and launch doorway for invited testers.
