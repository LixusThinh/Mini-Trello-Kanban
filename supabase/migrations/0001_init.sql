-- =====================================================================
-- Mini Trello / Kanban — Supabase schema (Database + Auth + Storage + Realtime)
-- Chạy 1 lần trong Dashboard > SQL Editor (hoặc `supabase db push`).
-- Script idempotent ở mức hợp lý: chạy trên project TRẮNG.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Schema private: chứa function nội bộ, KHÔNG expose qua Data API
-- ---------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  avatar_url  text,
  updated_at  timestamptz not null default now()
);

create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(btrim(title)) between 1 and 100),
  description text,
  owner_id    uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);

create table if not exists public.tasks (
  id             uuid primary key default gen_random_uuid(),
  project_id     uuid not null references public.projects (id) on delete cascade,
  title          text not null check (char_length(btrim(title)) between 1 and 200),
  description    text,
  status         text not null default 'TODO'
                 check (status in ('TODO', 'IN_PROGRESS', 'DONE')),
  attachment_url text,   -- public URL của ảnh trong bucket task-attachments
  created_by     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at     timestamptz not null default now()
);

-- Postgres KHÔNG tự index cột FK -> index tay (RLS + join + cascade đều dùng)
create index if not exists projects_owner_id_idx   on public.projects (owner_id, created_at desc);
create index if not exists tasks_project_id_idx    on public.tasks (project_id, created_at);
create index if not exists tasks_created_by_idx    on public.tasks (created_by);

-- ---------------------------------------------------------------------
-- 2. TRIGGERS
-- ---------------------------------------------------------------------
-- 2a. Tự tạo profile khi user đăng ký (full_name lấy từ signUp data)
--     user_metadata chỉ dùng để HIỂN THỊ, tuyệt đối không dùng cho phân quyền.
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke execute on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- 2b. Tự cập nhật updated_at của profiles
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

-- ---------------------------------------------------------------------
-- 3. GRANTS (từ 2026-10-30 bảng mới trong public KHÔNG tự expose ra Data API)
-- ---------------------------------------------------------------------
revoke all on public.profiles, public.projects, public.tasks from anon;
grant select, update                 on public.profiles to authenticated;
grant select, insert, update, delete on public.projects to authenticated;
grant select, insert, update, delete on public.tasks    to authenticated;

-- ---------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY
--    Luôn TO authenticated + điều kiện sở hữu; auth.uid() bọc trong (select ...)
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.tasks    enable row level security;

-- profiles: chỉ xem/sửa của chính mình (insert do trigger lo)
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- projects: owner toàn quyền
drop policy if exists projects_select_own on public.projects;
create policy projects_select_own on public.projects
  for select to authenticated
  using ((select auth.uid()) = owner_id);

drop policy if exists projects_insert_own on public.projects;
create policy projects_insert_own on public.projects
  for insert to authenticated
  with check ((select auth.uid()) = owner_id);

drop policy if exists projects_update_own on public.projects;
create policy projects_update_own on public.projects
  for update to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

drop policy if exists projects_delete_own on public.projects;
create policy projects_delete_own on public.projects
  for delete to authenticated
  using ((select auth.uid()) = owner_id);

-- tasks: thao tác được khi project chứa task thuộc về mình
drop policy if exists tasks_select_own_project on public.tasks;
create policy tasks_select_own_project on public.tasks
  for select to authenticated
  using (exists (
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = (select auth.uid())
  ));

drop policy if exists tasks_insert_own_project on public.tasks;
create policy tasks_insert_own_project on public.tasks
  for insert to authenticated
  with check (
    created_by = (select auth.uid())
    and exists (
      select 1 from public.projects p
      where p.id = tasks.project_id and p.owner_id = (select auth.uid())
    )
  );

drop policy if exists tasks_update_own_project on public.tasks;
create policy tasks_update_own_project on public.tasks
  for update to authenticated
  using (exists (
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = (select auth.uid())
  ))
  with check (exists (   -- chặn chuyển task sang project của người khác
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = (select auth.uid())
  ));

drop policy if exists tasks_delete_own_project on public.tasks;
create policy tasks_delete_own_project on public.tasks
  for delete to authenticated
  using (exists (
    select 1 from public.projects p
    where p.id = tasks.project_id and p.owner_id = (select auth.uid())
  ));

-- ---------------------------------------------------------------------
-- 5. REALTIME: tasks + projects đẩy thay đổi về client (.stream())
-- ---------------------------------------------------------------------
alter table public.tasks    replica identity full;  -- DELETE event mang đủ old record
alter table public.projects replica identity full;
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'tasks') then
    alter publication supabase_realtime add table public.tasks;
  end if;
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'projects') then
    alter publication supabase_realtime add table public.projects;
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 6. STORAGE: bucket ảnh đính kèm
--    Path quy ước: {project_id}/{uuid}.{ext}
--    Bucket public -> đọc ảnh qua getPublicUrl, KHÔNG cần policy SELECT rộng
--    (policy SELECT rộng chính là cái cảnh báo "Clients can list all files").
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('task-attachments', 'task-attachments', true, 5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- Helper ownership check dùng chung cho 4 policy storage
-- (SELECT cần cho list/delete/upsert, chỉ owner project mới list được folder của mình)
drop policy if exists attachments_select_owner on storage.objects;
create policy attachments_select_owner on storage.objects
  for select to authenticated
  using (
    bucket_id = 'task-attachments'
    and exists (select 1 from public.projects p
                where p.id::text = (storage.foldername(name))[1]
                  and p.owner_id = (select auth.uid()))
  );

drop policy if exists attachments_insert_owner on storage.objects;
create policy attachments_insert_owner on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'task-attachments'
    and exists (select 1 from public.projects p
                where p.id::text = (storage.foldername(name))[1]
                  and p.owner_id = (select auth.uid()))
  );

drop policy if exists attachments_update_owner on storage.objects;
create policy attachments_update_owner on storage.objects
  for update to authenticated
  using (
    bucket_id = 'task-attachments'
    and exists (select 1 from public.projects p
                where p.id::text = (storage.foldername(name))[1]
                  and p.owner_id = (select auth.uid()))
  )
  with check (
    bucket_id = 'task-attachments'
    and exists (select 1 from public.projects p
                where p.id::text = (storage.foldername(name))[1]
                  and p.owner_id = (select auth.uid()))
  );

drop policy if exists attachments_delete_owner on storage.objects;
create policy attachments_delete_owner on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'task-attachments'
    and exists (select 1 from public.projects p
                where p.id::text = (storage.foldername(name))[1]
                  and p.owner_id = (select auth.uid()))
  );
