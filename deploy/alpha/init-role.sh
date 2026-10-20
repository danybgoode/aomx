#!/bin/sh
set -eu

# Docker's Postgres entrypoint runs this only on a fresh aomx volume.
escaped=$(printf '%s' "$AOMX_INGEST_PASSWORD" | sed "s/'/''/g")
printf "CREATE ROLE aomx_ingest LOGIN PASSWORD '%s';\n" "$escaped" |
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
match_escaped=$(printf '%s' "$AOMX_MATCH_PASSWORD" | sed "s/'/''/g")
printf "CREATE ROLE aomx_match LOGIN PASSWORD '%s';\n" "$match_escaped" |
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<'SQL'
CREATE SCHEMA IF NOT EXISTS alpha_private;
REVOKE ALL ON SCHEMA alpha_private FROM PUBLIC;
SQL
