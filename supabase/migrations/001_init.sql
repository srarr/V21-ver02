-- Enable required extensions
create extension if not exists pgcrypto;

-- Basic tables for Phase 1
create table if not exists runs (
  id uuid primary key default gen_random_uuid(),
  status text not null check (status in ('PENDING','RUNNING','FAILED','COMPLETED')),
  prompt text,
  started_at timestamptz default now(),
  finished_at timestamptz
);

create table if not exists run_events (
  run_id uuid references runs(id) on delete cascade,
  seq int not null,
  phase text not null,
  type text not null check (type in ('status','artifact','error')),
  ts timestamptz default now(),
  payload jsonb,
  primary key (run_id, seq)
);

-- Indexes for better performance
create index if not exists idx_run_events_run_ts on run_events (run_id, ts);
create index if not exists idx_run_events_phase on run_events (phase);

create table if not exists portfolio_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  strategy jsonb,
  created_at timestamptz default now()
);

create table if not exists strategies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  dsl jsonb not null,
  created_at timestamptz default now()
);