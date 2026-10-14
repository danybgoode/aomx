-- Apply as the dedicated aomx database administrator, then grant only the
-- listed privileges to the aomx service role. No table is publicly routed.
create schema if not exists alpha_private;

create table if not exists alpha_private.audit_events (
  id bigint generated always as identity primary key,
  receipt_id uuid not null unique,
  event_id text,
  player_id text,
  match_id text,
  event_type text,
  status text not null check (status in ('accepted', 'excluded', 'rejected', 'quarantined')),
  payload_hash text not null,
  row jsonb not null,
  received_at timestamptz not null,
  constraint receipt_matches_row check (row->'receipt'->>'receipt_id' = receipt_id::text)
);
create index if not exists alpha_audit_player_idx on alpha_private.audit_events (player_id, id);
create unique index if not exists alpha_audit_event_once on alpha_private.audit_events (event_id)
  where status in ('accepted', 'excluded', 'quarantined') and event_id is not null;
create unique index if not exists alpha_audit_match_event_once on alpha_private.audit_events (player_id, match_id, event_type)
  where status in ('accepted', 'excluded') and match_id is not null;

create table if not exists alpha_private.observed_days (
  day date primary key,
  complete boolean not null default false,
  attested_at timestamptz not null default now(),
  note text not null
);
create table if not exists alpha_private.report_history (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  report jsonb not null,
  report_hash text not null unique
);
create table if not exists alpha_private.publication_days (
  metric_key text not null,
  day date not null,
  value numeric not null,
  report_hash text not null,
  published_at timestamptz not null default now(),
  primary key (metric_key, day)
);
create table if not exists alpha_private.invite_tokens (
  token_hash text primary key,
  label text not null,
  player_id text unique,
  claimed_at timestamptz,
  revoked boolean not null default false,
  created_at timestamptz not null default now()
);

revoke all on schema alpha_private from public;
revoke all on all tables in schema alpha_private from public;
-- Run as administrator after creating a LOGIN role with a private password:
-- grant usage on schema alpha_private to aomx_ingest;
-- grant select, insert on all tables in schema alpha_private to aomx_ingest;
-- grant usage, select on all sequences in schema alpha_private to aomx_ingest;
