# PRD — V21 Claude Code Accelerator (Local‑first)
**Date:** 2025-08-27

## 1) Project Summary
- **Name:** V21 Local Project
- **Goal:** ให้ Claude Code ทำงานแบบมี “หน่วยความจำภายนอก” ผ่านไฟล์ 4 ชิ้น (PRD, PLANNING, CLAUDE, TASKS) + Supabase Local เก็บสัญญา/สเตตัส/ลอค/อาร์ติแฟกต์
- **Scope:** Frontend (sveltekit + tailwind+shadcn), Backend (go/Gin), DB (postgres via supabase), Sub‑Agents (PRD Keeper, Contract Scribe, DB Cartographer, UI Enforcer, Task Runner, Verifier)

## 2) Problems (จากโปรเจกต์เก่า)
- ไฟล์ซ้ำ/โครงสร้างนอกสเปก, UI ไม่ตรง Figma, ไม่มีสัญญา API/DB ชัดเจน

## 3) Goals & Non‑Goals
**Goals**
- มีสัญญา OpenAPI + SQL ก่อนเขียนโค้ด (contract‑first)
- ใช้ V21.ini เป็น source of truth
- Sub‑Agent loop และ DoD ชัดเจนต่อ task
**Non‑Goals**
- ไม่ทำ microservices ตั้งแต่แรก
- Local‑first โดยใช้ Supabase Local

## 4) Personas & Use Cases
- **Owner/Architect**: ให้นิยาม PRD/V21.ini
- **Engineer**: ทำงานจาก TASKS.md ทีละก้อน
- **Verifier(CI)**: ตรวจ DoD, lint, unit/e2e, contract tests

## 5) Success Metrics
- Task ผ่าน DoD โดยไม่แก้เกิน 1 รอบ ≥ 80%
- UI screenshot diff < 0.03
- ไม่มีไฟล์นอก allowlist: `apps/web,apps/api,contracts,ops,PRD.md,PLANNING.md,CLAUDE.md,TASKS.md,V21.ini`

## 6) Deliverables
- โครงรีโปพร้อมรัน local
- OpenAPI `contracts/openapi.yaml`
- SQL migrations + seeds
- Makefile/สคริปต์ dev
- เทมเพลต Sub‑Agents + Prompts
