# Heliox ATLAS v21 - Project Context

Please load the following project files to understand the system architecture:

1. **ROADMAP.md** - Complete development phases and timeline
2. **CONTINUITY.md** - Current progress and next steps  
3. **CLAUDE.md** - Project architecture and best practices

## Project Overview
- **Name:** Heliox ATLAS v21
- **Type:** Quantitative Trading Platform
- **Tech Stack:** Go API, SvelteKit UI, LangGraph Orchestrator, Rust Backtest Engine
- **Database:** Supabase (PostgreSQL)
- **Current Phase:** Ready to begin Phase 1.2 (API Implementation)

## Key Features
- Natural language to trading strategy generation
- High-performance backtesting engine
- Real-time broker integration
- Risk management and portfolio optimization

## Development Environment
- WSL (Windows Subsystem for Linux)
- Working directory: /mnt/c/New Claude Code/V21 Ver01
- Flexible setup with mock data for UI development
- Contract-first development with OpenAPI schemas

## Quick Commands
- `make dev` - Start all services
- `make db-up` - Start Supabase
- `make test` - Run tests
- `make help` - See all commands

## Important Notes
- The setup is intentionally flexible (not locked/rigid)
- Mock data is available for UI development without backend
- Use SSE (Server-Sent Events) for real-time updates
- Follow the contract schemas in /contracts directory

## AUTOMATIC CHECKPOINT MANAGEMENT 🤖

**IMPORTANT: Run checkpoint-manager AUTOMATICALLY (without waiting for user request) after:**
- ✅ Completing ANY task or marking something as done
- ✅ Finishing ANY Phase work or milestone
- ✅ Making commits with code changes
- ✅ Updating todos.json, PHASE1-TASKS.md, or tracking files
- ✅ At the START of each new session

### AUTO-EXECUTION RULE:
```
After any of the above actions, IMMEDIATELY run:
/agents checkpoint-manager "auto-update after [action]"

DO NOT wait for user permission - run PROACTIVELY
```

### When to run checkpoint-manager:

### How to use:
```bash
# Quick status check
/agents checkpoint-manager "status"

# Auto-detect and fix issues
/agents checkpoint-manager "verify and fix"

# After completing work
/agents checkpoint-manager "update after [task description]"

# Generate progress report
/agents checkpoint-manager "report"
```

### What the agent does:
- 🔍 Detects phase/task status mismatches
- 🔧 Auto-repairs inconsistencies
- 📊 Updates statistics correctly
- 🧹 Cleans duplicate entries
- 📝 Syncs all tracking files
- 💾 Creates backups before changes

### Git Integration:
Git hooks will remind you when to run checkpoint-manager.
Look for the yellow reminder box after commits.

## ON SESSION START (RUN IMMEDIATELY)
1. **First action when session begins:**
   ```bash
   /agents checkpoint-manager "session start verification"
   ```
2. Check for any pending issues from last session
3. Show current project progress status
4. Verify all tracking files are in sync

## PROACTIVE BEHAVIOR EXPECTED
- Don't ask "Should I run checkpoint-manager?" - Just run it
- After task completion, auto-run before reporting to user
- Include checkpoint status in task completion messages
- If inconsistencies found, fix them immediately