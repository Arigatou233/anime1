-- 番剧档案馆 Supabase 数据库基础结构
-- 在 Supabase Dashboard -> SQL Editor 执行。
-- 上线前请先在 Authentication 中启用 Email 登录，并把你的账号 ID 设置为管理员。
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists public.anime (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  year integer,
  season text check (season in ('冬季','春季','夏季','秋季')),
  cover_url text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.cut_records (
  id uuid primary key default gen_random_uuid(),
  anime_id uuid not null references public.anime(id) on delete cascade,
  episode integer not null check (episode > 0),
  time_point text not null,
  description text not null,
  source_note text,
  created_at timestamptz not null default now()
);
-- 所有用户的修改先进入 proposals，不允许普通用户直接写 anime / cut_records。
create table if not exists public.proposals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  anime_id uuid references public.anime(id) on delete set null,
  action text not null check (action in ('create_anime','update_anime','delete_anime','add_cut','update_cut','delete_cut')),
  payload jsonb not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  admin_note text,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  anime_id uuid references public.anime(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.anime enable row level security;
alter table public.cut_records enable row level security;
alter table public.proposals enable row level security;
alter table public.comments enable row level security;

-- profiles：用户只能读写自己的非管理员资料；管理员标记不可由客户端自行更改。
create policy "profile read own" on public.profiles for select to authenticated using (id = auth.uid());
create policy "profile insert own" on public.profiles for insert to authenticated with check (id = auth.uid() and is_admin = false);
create policy "profile update own display name" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and is_admin = false);

-- 公开读正式档案。禁止客户端直接 insert/update/delete，发布操作由可信管理员工作流执行。
create policy "public read anime" on public.anime for select to anon, authenticated using (true);
create policy "public read cuts" on public.cut_records for select to anon, authenticated using (true);

-- 投稿人只能查看自己的投稿、创建自己的待审投稿；不能自行改状态或审核字段。
create policy "read own proposals" on public.proposals for select to authenticated using (user_id = auth.uid());
create policy "submit pending proposals" on public.proposals for insert to authenticated with check (user_id = auth.uid() and status = 'pending' and reviewed_by is null and reviewed_at is null);
-- 留言公开只显示审核通过内容；用户只能提交待审核留言。
create policy "read approved comments" on public.comments for select to anon, authenticated using (status = 'approved');
create policy "submit pending comments" on public.comments for insert to authenticated with check (user_id = auth.uid() and status = 'pending');

-- 重要：请勿将 service_role key 放入前端或 GitHub 仓库。
-- 管理员审核/合并应通过受保护的 Edge Function（服务端校验 profiles.is_admin）执行，
-- 或由你在 Supabase Dashboard 中人工审核。不要给浏览器端直接修改正式表的权限。
-- 创建第一个管理员：注册登录一次后，在 Supabase SQL Editor 用你的真实 auth user UUID 执行：
-- update public.profiles set is_admin = true where id = '替换为你的用户UUID';
-- 注意：如使用上面 update policy，管理员标记请仅由 SQL Editor / service role 修改。
