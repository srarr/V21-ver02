# CLAUDE.md — Operating Guide (No‑Assumptions)
> Claude Code ต้องอ่านไฟล์นี้ก่อนเริ่มงานเสมอ

## Startup Checklist
1) โหลด/พาร์ส `V21.ini`
2) อ่าน `PLANNING.md`
3) อ่าน `TASKS.md` แล้วเลือกงาน `TODO` ตัวแรก
4) ตรวจสัญญา: ถ้าไม่มี OpenAPI/SQL ที่จำเป็นสำหรับงานนั้น ให้ **สร้างก่อน** แล้วจึงโค้ด

## ENV (ห้ามเดา)
- `BACKEND_HTTP_ADDR` = `http://localhost:8080`
- `SUPABASE_PROJECT_URL` = `http://localhost:54321`
- `SUPABASE_ANON_KEY` = (เติมจาก `supabase status`)
- `POSTGRES_DSN` = `postgres://postgres:postgres@localhost:54322/postgres?sslmode=disable`

## Sub‑Agents
- **PRD Keeper** — ตรวจความสอดคล้อง PRD กับ V21.ini และเสนอแพตช์แบบ diff
- **Contract Scribe** — สร้าง/อัปเดต `contracts/openapi.yaml` (หยุดถ้าชน ambiguity)
- **DB Cartographer** — แปลง models → 3NF SQL + migrations + seed
- **UI Enforcer** — ผูก Figma tokens → Tailwind config + components + screenshot‑diff tests
- **Task Runner** — implement งานเดียวจาก TASKS.md ตามสัญญาเท่านั้น + tests
- **Verifier** — รัน unit/e2e/contract tests และสรุปล้มเหลวพร้อมไฟล์:บรรทัด

## Guardrails (จากโปรเจกต์เก่า)
- ห้ามสร้างไฟล์นอก allowlist: `apps/web,apps/api,contracts,ops,PRD.md,PLANNING.md,CLAUDE.md,TASKS.md,V21.ini`
- ต้องมี Playwright screenshot test บน key screens
- ห้าม call API/DB โดยไม่มีสัญญา (OpenAPI/SQL)

## Plan Mode Kickoff Prompt
```
Please read PLANNING.md, CLAUDE.md, and TASKS.md. Parse V21.ini first.
Work on the first TODO. If contracts (OpenAPI/SQL) are missing, create them first.
Use Sub‑Agent loop: Keeper → Scribe → Cartographer → Runner → Verifier.
Never write files outside the repo allowlist in PLANNING.md.
Emit unified diffs for any file changes.
```
