#!/usr/bin/env bash
set -euo pipefail
supabase init || true
supabase start
supabase status
