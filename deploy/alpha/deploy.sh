#!/usr/bin/env bash
# Run the ingest and match servers at a reviewed commit, from images CI built (.github/workflows/alpha-images.yml).
# Run on the VM:
#   /opt/aomx/repo/deploy/alpha/deploy.sh <ingest-sha> [<match-sha>]     # match defaults to the ingest commit
#
# The chosen tags are written to /opt/aomx/compose.env, so every later `docker compose` call (logs, ps, exec) and
# the next operator see what is running. Before this they lived only in the shell of whoever last ran
# `export AOMX_IMAGE_TAG=...`, and on 2026-10-29 ingest and match were found running different commits with
# nothing on disk saying which.
#
# This script deploys IMAGES only. Moving the /opt/aomx/repo release symlink (which the backup, health, report and
# retention timers run from) and applying migrations stay the reviewed manual steps in README.md.
set -euo pipefail

INGEST_TAG="${1:?usage: deploy.sh <ingest-sha> [<match-sha>]}"
MATCH_TAG="${2:-$INGEST_TAG}"
REGISTRY=ghcr.io/danybgoode/
ENV_FILE=/opt/aomx/compose.env
COMPOSE=(docker compose -p aomx --env-file "$ENV_FILE" -f /opt/aomx/repo/deploy/alpha/compose.yml)

for t in "$INGEST_TAG" "$MATCH_TAG"; do
  case "$t" in *[!0-9a-f]*|"") echo "✗ '$t' is not a commit ID" >&2; exit 1;; esac
done

# Pull BEFORE touching anything: a commit CI has not built leaves the running servers alone.
docker pull -q "${REGISTRY}aomx-ingest:$INGEST_TAG" >/dev/null || { echo "✗ no image ${REGISTRY}aomx-ingest:$INGEST_TAG — run the Alpha images workflow for that commit" >&2; exit 1; }
docker pull -q "${REGISTRY}aomx-match:$MATCH_TAG" >/dev/null || { echo "✗ no image ${REGISTRY}aomx-match:$MATCH_TAG — run the Alpha images workflow for that commit" >&2; exit 1; }

[ -f "$ENV_FILE" ] && cp -p "$ENV_FILE" "$ENV_FILE.prev"
umask 077
printf 'AOMX_IMAGE_REGISTRY=%s\nAOMX_IMAGE_TAG=%s\nAOMX_MATCH_IMAGE_TAG=%s\n' "$REGISTRY" "$INGEST_TAG" "$MATCH_TAG" > "$ENV_FILE"

"${COMPOSE[@]}" up -d --no-build ingest match

for svc in ingest match; do
  for _ in $(seq 1 40); do
    s=$(docker inspect -f '{{.State.Health.Status}}' "aomx-$svc-1" 2>/dev/null || echo missing)
    [ "$s" = healthy ] && break
    sleep 3
  done
  [ "$s" = healthy ] || { echo "✗ aomx-$svc-1 is $s — previous tags are in $ENV_FILE.prev; re-run with them to roll back" >&2; exit 1; }
  echo "✓ aomx-$svc-1 healthy ($(docker inspect -f '{{.Config.Image}}' "aomx-$svc-1"))"
done

# Keep the running image and the two newest others per service: rollback targets without filling the boot disk.
for name in aomx-ingest aomx-match; do
  running=$(docker inspect -f '{{.Config.Image}}' "${name}-1" 2>/dev/null || true)
  docker images "${REGISTRY}${name}" --format '{{.Repository}}:{{.Tag}}' | grep -vxF "$running" | tail -n +3 \
    | xargs -r docker rmi >/dev/null 2>&1 || true
done
