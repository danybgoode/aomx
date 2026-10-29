#!/usr/bin/env bash
# Weekly restore drill: take a backup, restore that exact object from OCI into the disposable database named by
# AOMX_RESTORE_DATABASE_URL, and compare row counts with the live database (scripts/alpha-backup.mjs --restore-test).
# Run by aomx-restore-drill.timer. Until 2026-10-29 this ran only by hand, so a backup nobody had restored was
# the only recovery path.
#
# The restore database is dropped again on exit. A restored copy is NOT a backup that expires: the participant
# notice promises deleted data is gone within 30 days, and on 2026-10-29 two forgotten restore databases on this
# host still held copies of live audit events.
set -euo pipefail
: "${AOMX_RESTORE_DATABASE_URL:?}" "${AOMX_BACKUP_DATABASE_URL:?}" "${AOMX_PG_DOCKER_CONTAINER:?}"

dbname() { local u="${1%%\?*}"; printf '%s' "${u##*/}"; }
target=$(dbname "$AOMX_RESTORE_DATABASE_URL")
live=$(dbname "$AOMX_BACKUP_DATABASE_URL")

# This script DROPS a database. Refuse anything that is, or could be, the live one.
case "$target" in
  ""|"$live"|postgres|template0|template1) echo "✗ refusing to clear database '$target'" >&2; exit 1 ;;
esac
[[ "$target" == *restore* ]] || { echo "✗ refusing: '$target' is not named as a restore database" >&2; exit 1; }

psql_admin() { docker exec "$AOMX_PG_DOCKER_CONTAINER" psql -v ON_ERROR_STOP=1 -qU aomx_admin -d postgres "$@"; }
drop() { psql_admin -c "DROP DATABASE IF EXISTS \"$target\" WITH (FORCE)"; }

drop
psql_admin -c "CREATE DATABASE \"$target\""
trap 'drop || echo "! could not drop $target — remove it by hand: it holds a copy of live data" >&2' EXIT

node scripts/alpha-backup.mjs --restore-test
echo "✓ restore drill passed; $target dropped"
