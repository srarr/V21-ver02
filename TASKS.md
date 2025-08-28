# TASKS — Milestones & Actionable Tasks (Phase 2–7)
> ทำทีละงาน มี DoD ชัดเจน

## Phase 2 — Local Infra & Contracts
- [ ] T2.1 Init Supabase Local — DoD: .env พร้อม URL/ANON
- [ ] T2.2 Apply DB Schema — DoD: ตารางสร้างครบ, seed สำเร็จ
- [ ] T2.3 Draft OpenAPI v0.1 — DoD: Schemathesis ผ่าน smoke test

## Phase 3 — Backend API Scaffold (Go/Gin)
- [ ] T3.1 Bootstrap apps/api — healthz, config, log
- [ ] T3.2 /api/v1/projects GET/POST — tests ผ่าน + match OpenAPI
- [ ] T3.3 /api/v1/docs GET/POST — เก็บ PRD/PLANNING/CLAUDE/TASKS

## Phase 4 — Frontend Scaffold (SvelteKit)
- [ ] T4.1 apps/web — Tailwind + shadcn‑svelte + Query
- [ ] T4.2 Figma Token Mapping — screenshot‑diff < 3%

## Phase 5 — Auth & Policies
- [ ] T5.1 Supabase Auth (Email OTP/Link)
- [ ] T5.2 RLS Policies (ถ้าจำเป็น)

## Phase 6 — Sub‑Agents & Automation
- [ ] T6.1 Register Sub‑Agents (ตาม CLAUDE.md)
- [ ] T6.2 Verifier Pipeline (`make verify`)

## Phase 7 — Hardening & UX Polish
- [ ] T7.1 Duplicate/Drift Guards
- [ ] T7.2 DX Quality (README, make help, error catalog)
