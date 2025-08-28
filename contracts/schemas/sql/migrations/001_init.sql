-- 001_init.sql
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz default now()
);

do $$
begin
  if not exists (select 1 from pg_type where typname = 'doc_type') then
    create type doc_type as enum ('PRD','PLANNING','CLAUDE','TASKS');
  end if;
end$$;

create table if not exists docs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  type doc_type not null,
  content text not null,
  updated_at timestamptz default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  title text not null,
  body text,
  phase int not null,
  status text not null check (status in ('TODO','DOING','BLOCKED','DONE')),
  dod jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists task_runs (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references tasks(id) on delete cascade,
  started_at timestamptz default now(),
  finished_at timestamptz,
  success boolean,
  log text
);

create table if not exists subagents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references projects(id) on delete cascade,
  name text not null,
  role text not null,
  prompt text not null
);

insert into projects (name, description)
values ('V21 Local Project','Local-first Claude Code accelerator')
on conflict do nothing;
