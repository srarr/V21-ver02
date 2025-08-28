#!/usr/bin/env python3
# Re-generate 4-file framework from V21.ini
import configparser, datetime, os, sys, json, textwrap
BASE = os.path.abspath(os.path.dirname(__file__))
ini_path = os.path.join(BASE, "V21.ini")
cfg = configparser.ConfigParser()
cfg.read(ini_path, encoding="utf-8")

def get(section, key, default=None):
    try:
        return cfg.get(section, key)
    except Exception:
        return default

frontend_framework = get("frontend","framework","sveltekit")
frontend_ui = get("frontend","ui","tailwind+shadcn")
backend_lang = get("backend","language","go")
backend_auth = get("backend","auth","supabase")
db_engine = get("db","engine","postgres")
db_local = get("db","local","supabase")
ui_thresh = get("guardrails","ui_screenshot_diff_threshold","0.03")
allowlist = get("guardrails","allowlist","apps/web,apps/api,contracts,ops,PRD.md,PLANNING.md,CLAUDE.md,TASKS.md,V21.ini")
now = datetime.datetime.now().strftime("%Y-%m-%d")

# (Minified) write PRD/CLAUDE/PLANNING/TASKS like initial generation (omitted for brevity here)
# In practice, you'd port the same templates used in the first build script.
print("Regeneration script placeholder — use the main pack for initial scaffolding.")
