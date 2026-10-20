-- A short-lived withdrawal marker prevents an active match from restoring a
-- record after its participant has requested deletion.
create table if not exists alpha_private.player_deletions (
  player_hash text primary key,
  deleted_at timestamptz not null default now()
);
revoke all on alpha_private.player_deletions from public;
grant usage on schema alpha_private to aomx_retention;
grant select, delete on alpha_private.audit_events to aomx_retention;
grant select, delete on alpha_private.match_records to aomx_retention;
grant select, delete on alpha_private.invite_tokens to aomx_retention;
grant select, insert, update, delete on alpha_private.player_deletions to aomx_retention;
grant select on alpha_private.player_deletions to aomx_match;
grant select on alpha_private.player_deletions to aomx_ingest;
