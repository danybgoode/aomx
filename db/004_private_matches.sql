-- Apply as aomx_admin after creating aomx_match with a distinct private password.
-- The role can bind invite codes and store completed match evidence, but cannot
-- read funnel audits, publish measurements or administer invitations.
create table if not exists alpha_private.match_records (
  match_id text primary key,
  created_at timestamptz not null default now(),
  terminal_at timestamptz not null default now(),
  players jsonb not null,
  terminal jsonb not null,
  replay jsonb not null,
  record_hash text not null,
  constraint match_record_players check (jsonb_array_length(players) = 2)
);
revoke all on alpha_private.match_records from public;
grant usage on schema alpha_private to aomx_match;
grant select on alpha_private.invite_tokens to aomx_match;
grant update (player_id, claimed_at) on alpha_private.invite_tokens to aomx_match;
grant select, insert on alpha_private.match_records to aomx_match;
