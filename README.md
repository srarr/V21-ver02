# V21 Framework Project (Local-first)

## Quickstart
1. Install Supabase CLI, Go, pnpm
2. `cp .env.example .env` แล้วเติมค่า `SUPABASE_*` จาก `supabase status`
3. `supabase start`
4. เปิด Claude Code → Plan Mode → ใช้ Kickoff Prompt ใน `CLAUDE.md`
5. ทำงานจาก `TASKS.md` ทีละงาน

## Contracts
- OpenAPI: `contracts/openapi.yaml`
- SQL: `contracts/schemas/sql/migrations/`

## From V21.ini
- frontend.framework = sveltekit
- frontend.ui = tailwind+shadcn
- backend.language = go
- backend.auth = supabase
- db.engine = postgres
- db.local = supabase
- guardrails.ui_screenshot_diff_threshold = 0.03
- guardrails.allowlist = apps/web,apps/api,contracts,ops,PRD.md,PLANNING.md,CLAUDE.md,TASKS.md,V21.ini