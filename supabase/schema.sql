-- SecondLife: planned Supabase schema (NOT yet connected to the frontend).
-- Run in the Supabase SQL editor when the Supabase integration is added.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.components (
  id text primary key,
  name text not null,
  normalized_name text generated always as (lower(trim(name))) stored,
  category text not null,
  description text,
  estimated_unit_price numeric(10,2) not null default 0,   -- INR, demo reference price
  estimated_weight_grams numeric(10,2) not null default 0,
  specifications text,
  created_at timestamptz not null default now()
);

create table if not exists public.inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  component_id text not null references public.components(id),
  quantity integer not null check (quantity >= 1),
  condition text not null check (condition in ('Working','Needs testing','Not working')),
  specifications text,
  notes text,
  source text,
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id text primary key,
  name text not null,
  slug text not null unique,
  description text,
  category text not null,
  difficulty text not null check (difficulty in ('Beginner','Intermediate','Advanced')),
  estimated_duration_minutes integer not null,
  estimated_new_product_price numeric(10,2) not null,
  consumables_cost numeric(10,2) not null default 0,
  requires_spec_check boolean not null default false,
  instructions jsonb not null default '[]',
  safety_notes jsonb not null default '[]',
  created_at timestamptz not null default now()
);

create table if not exists public.project_requirements (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references public.projects(id) on delete cascade,
  component_id text not null references public.components(id),
  required_quantity integer not null check (required_quantity >= 1),
  compatible_alternatives text[] not null default '{}',
  is_critical boolean not null default false
);

create table if not exists public.user_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id text not null references public.projects(id),
  status text not null default 'saved' check (status in ('saved','planned','in_progress','completed')),
  match_percentage_at_save numeric(5,2),
  estimated_build_cost_at_save numeric(10,2),
  progress integer not null default 0 check (progress between 0 and 100),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, project_id)            -- prevents duplicate saved projects
);

-- Row Level Security: users only see their own rows. Catalog tables are readable by everyone.
alter table public.profiles enable row level security;
alter table public.inventory enable row level security;
alter table public.user_projects enable row level security;

create policy "own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);
create policy "own inventory" on public.inventory for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own projects" on public.user_projects for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

alter table public.components enable row level security;
alter table public.projects enable row level security;
alter table public.project_requirements enable row level security;
create policy "catalog read components" on public.components for select using (true);
create policy "catalog read projects" on public.projects for select using (true);
create policy "catalog read requirements" on public.project_requirements for select using (true);
