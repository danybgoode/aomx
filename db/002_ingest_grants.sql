-- Run after 001 as aomx_admin. The public ingest role cannot alter reports or
-- issue invites, and it cannot reach any panfleto database.
grant usage on schema alpha_private to aomx_ingest;
grant select, insert on alpha_private.audit_events to aomx_ingest;
grant usage, select on sequence alpha_private.audit_events_id_seq to aomx_ingest;
grant select on alpha_private.invite_tokens to aomx_ingest;
grant update (player_id, claimed_at) on alpha_private.invite_tokens to aomx_ingest;
