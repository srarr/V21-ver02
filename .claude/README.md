# Claude Code - Quick Reference

## 🚀 First Time Setup (WSL)

1. **Install aliases** (one-time):
   ```bash
   ./setup-wsl-aliases.sh
   source ~/.bashrc  # or ~/.zshrc
   ```

2. **Test setup**:
   ```bash
   heliox-status    # Check project status
   heliox-claude    # Open Claude Code
   ```

## 📝 Every Session - Load Context

When opening Claude Code, always load these files:
```
Please load: ROADMAP.md, CONTINUITY.md, and CLAUDE.md
```

Or copy this exact message:
```
Please load project context from ROADMAP.md, CONTINUITY.md, and CLAUDE.md
```

## ⚡ Quick Commands

| Command | Description |
|---------|-------------|
| `heliox` | Navigate to project |
| `heliox-start` | Run startup script |
| `heliox-dev` | Start all services |
| `heliox-db` | Start Supabase |
| `heliox-claude` | Open Claude Code |
| `heliox-status` | Check status |
| `heliox-help` | Show all commands |

## 🔧 Manual Commands

Without aliases:
```bash
# Navigate to project
cd "/mnt/c/New Claude Code/V21 Ver01"

# Run startup script
./start-heliox.sh

# Start development
make dev

# Start database
make db-up
```

## 📁 Important Files

- **ROADMAP.md** - All development phases (1-10)
- **CONTINUITY.md** - Current progress tracker
- **CLAUDE.md** - Architecture and patterns
- **Makefile** - All make commands
- **.env** - Environment configuration

## 🎯 Current Status

- **Phase:** Ready for 1.2 (API Implementation)
- **Next Steps:**
  1. Create Go API with /healthz endpoint
  2. Implement /v1/runs endpoints
  3. Add SSE streaming support

## 💡 Tips

1. **Auto-load on terminal start** (optional):
   Add to ~/.bashrc or ~/.zshrc:
   ```bash
   heliox-status  # Shows project status
   ```

2. **Check prerequisites**:
   ```bash
   ./scripts/check-prereqs.sh
   ```

3. **Quick start everything**:
   ```bash
   ./scripts/quick-start.sh
   ```

## 🛠️ Development Workflow

1. Open terminal (WSL)
2. Run: `heliox-claude`
3. In Claude Code: Load ROADMAP.md, CONTINUITY.md, CLAUDE.md
4. Start coding!

## 📚 Documentation

- `/contracts/` - OpenAPI schemas and fixtures
- `/docs/` - Additional documentation
- `/.claude/` - Claude-specific files

---

**Remember:** This project uses flexible configuration - nothing is locked or rigid. Mock data is available for UI development without backend dependencies.