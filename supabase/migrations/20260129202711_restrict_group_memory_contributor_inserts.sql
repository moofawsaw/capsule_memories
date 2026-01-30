-- Prevent creators from auto-adding group members directly to memory_contributors.
-- For group-based memories (memories.group_id IS NOT NULL), members must join via memory_invites acceptance.
--
-- We keep:
-- - users managing their own membership (user_id = auth.uid())
-- - creators able to view/update/delete contributors
-- But restrict creator INSERT of other users to NON-group memories only.

begin;

-- Replace overly-permissive creator ALL policy
drop policy if exists memory_creators_manage_contributors on public.memory_contributors;

-- Creators can view contributors for their memories
create policy memory_creators_select_contributors
on public.memory_contributors
for select
to authenticated
using (is_memory_creator(memory_id));

-- Creators can update contributor rows for their memories (rare, but keep parity)
create policy memory_creators_update_contributors
on public.memory_contributors
for update
to authenticated
using (is_memory_creator(memory_id))
with check (is_memory_creator(memory_id));

-- Creators can remove contributors for their memories
create policy memory_creators_delete_contributors
on public.memory_contributors
for delete
to authenticated
using (is_memory_creator(memory_id));

-- Creators can INSERT contributors ONLY for NON-group memories.
-- This blocks the old client behavior of auto-adding group-selected users.
create policy memory_creators_insert_contributors_non_group_only
on public.memory_contributors
for insert
to authenticated
with check (
  is_memory_creator(memory_id)
  and exists (
    select 1
    from public.memories m
    where m.id = memory_contributors.memory_id
      and m.group_id is null
  )
);

commit;
;
