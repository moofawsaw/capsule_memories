-- Allows a user to leave a memory without destroying their ability to re-join.
-- Behavior:
-- - Deletes the user's contributor row (leave)
-- - Ensures a memory_invites row exists and is set back to 'pending'
-- - Does NOT send a new invite notification/push when creating the invite row

create or replace function public.leave_memory_keep_invite_pending(p_memory_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public', 'auth'
as $$
declare
  v_user_id uuid;
  v_creator_id uuid;
  v_existing_invite_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select m.creator_id into v_creator_id
  from public.memories m
  where m.id = p_memory_id;

  if v_creator_id is null then
    raise exception 'Memory not found';
  end if;

  if v_creator_id = v_user_id then
    raise exception 'Creator cannot leave their own memory';
  end if;

  -- Remove membership
  delete from public.memory_contributors
  where memory_id = p_memory_id
    and user_id = v_user_id;

  -- If invite exists, flip it back to pending.
  select mi.id into v_existing_invite_id
  from public.memory_invites mi
  where mi.memory_id = p_memory_id
    and mi.user_id = v_user_id
  limit 1;

  if v_existing_invite_id is not null then
    update public.memory_invites
    set status = 'pending'::public.memory_invite_status,
        responded_at = null
    where id = v_existing_invite_id;
  else
    -- Create an invite row without firing the "pending invite created" trigger.
    -- We insert as accepted (no notify on insert), then flip to pending.
    insert into public.memory_invites (memory_id, user_id, invited_by, status, created_at, responded_at)
    values (p_memory_id, v_user_id, v_creator_id, 'accepted'::public.memory_invite_status, current_timestamp, current_timestamp)
    returning id into v_existing_invite_id;

    update public.memory_invites
    set status = 'pending'::public.memory_invite_status,
        responded_at = null
    where id = v_existing_invite_id;
  end if;
end;
$$;
;
