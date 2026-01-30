-- Create in-app notification when a user is directly added as a memory contributor (e.g., via groups flow)

create or replace function public.notify_memory_contributor_added()
returns trigger
language plpgsql
security definer
set search_path = 'public', 'auth'
as $$
declare
  actor_id uuid;
  memory_title text;
  actor_name text;
  notification_data jsonb;
begin
  actor_id := auth.uid();

  if actor_id is null then
    -- If this insert was performed with service role (no JWT), fall back to memory creator.
    select m.creator_id, m.title
      into actor_id, memory_title
    from public.memories m
    where m.id = new.memory_id;
  else
    select m.title
      into memory_title
    from public.memories m
    where m.id = new.memory_id;
  end if;

  -- Don’t notify a user about adding themselves (e.g., accepting an invite / joining).
  if actor_id is not null and new.user_id = actor_id then
    return new;
  end if;

  select up.display_name
    into actor_name
  from public.user_profiles up
  where up.id = actor_id;

  notification_data := jsonb_build_object(
    'actor_user_id', actor_id,
    'memory_id', new.memory_id,
    'memory_title', coalesce(memory_title, 'a memory'),
    'invited_by', actor_id,
    'inviter_id', actor_id,
    'inviter_name', coalesce(actor_name, 'Someone'),
    'sender_name', coalesce(actor_name, 'Someone'),
    'user_id', actor_id
  );

  insert into public.notifications (
    user_id,
    type,
    title,
    message,
    data,
    is_read,
    created_at
  ) values (
    new.user_id,
    'memory_invite'::public.notification_type,
    'Memory Invitation',
    coalesce(actor_name, 'Someone') || ' invited you to join ' || coalesce(memory_title, 'a memory'),
    notification_data,
    false,
    current_timestamp
  );

  return new;
end;
$$;

drop trigger if exists notify_memory_contributor_added_trigger on public.memory_contributors;
create trigger notify_memory_contributor_added_trigger
after insert on public.memory_contributors
for each row
execute function public.notify_memory_contributor_added();
;
