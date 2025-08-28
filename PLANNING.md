# PLANNING — Architecture & Implementation Plan

## Tech Stack (from V21.ini)
- **Frontend:** sveltekit + Tailwind + shadcn‑svelte, TanStack Query, Zod
- **Backend:** Go 1.22 + Gin, Wire (DI), Zap logs
- **DB/Infra:** Supabase Local (postgres + Auth + Storage)
- **Tests:** Vitest/Playwright (FE), Go test + httptest (BE), Schemathesis (OpenAPI)

## Repo Structure (Allowlist)
```
apps/
  web/
  api/
contracts/
  openapi.yaml
  schemas/
    json/
    sql/
      migrations/
      seed/
ops/
  supabase/
  ci/
  scripts/

PRD.md
PLANNING.md
CLAUDE.md
TASKS.md
V21.ini
```

## ENV Contracts — `.env.example`
```
BACKEND_HTTP_ADDR=http://localhost:8080
SUPABASE_PROJECT_URL=http://localhost:54321
SUPABASE_ANON_KEY=REPLACE_ME
POSTGRES_DSN=postgres://postgres:postgres@localhost:54322/postgres?sslmode=disable
```

## Supabase Local
```
supabase init
supabase start
supabase status   # จดค่า ANON/URLs แล้วเติมใน .env
supabase stop
```

## OpenAPI Starter — `contracts/openapi.yaml`
ดูไฟล์จริงในโฟลเดอร์ `contracts/` (พร้อมเริ่มทดสอบด้วย Schemathesis)

## SQL Migrations
ไฟล์เริ่มต้นใน `contracts/schemas/sql/migrations/001_init.sql`

## CI/Verification
- Schemathesis: ยิง contract tests จาก `openapi.yaml`
- Lints: golangci-lint, eslint/prettier
- Playwright: screenshot‑diff < 0.03
