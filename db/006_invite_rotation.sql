-- A revoked code keeps its historical player binding for match audit, while
-- the same installation may claim one new active code. Apply as aomx_admin.
begin;
alter table alpha_private.invite_tokens
  drop constraint if exists invite_tokens_player_id_key;
create unique index if not exists invite_tokens_active_player_id_key
  on alpha_private.invite_tokens (player_id)
  where revoked = false and player_id is not null;
commit;
