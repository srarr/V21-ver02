# Continuity Guide - How to Resume Development

## 📍 Current Status: Phase 1.2 COMPLETED

### Last Updated: 2024-08-28
- Fixed OpenAPI contract (was using wrong project spec!)
- Renamed migration file: 001_init.sql
- Validated OpenAPI spec
- Ready for Phase 1.2: API Implementation

## 🔄 Quick Start Checklist

### When Starting a New Session
```bash
# 1. Check current state
cat HANDOFF.md

# 2. Load context
source .claude/load-context.sh

# 3. Verify environment
./scripts/verify-setup.sh

# 4. Run tests to ensure nothing broke
make test-integration

# 5. Check git status
git status
git log --oneline -10
```

## 📂 Project State Files

### Files That Track Progress
1. **HANDOFF.md** - Current implementation status
2. **DECISIONS.md** - Why we chose X over Y
3. **.claude/context.json** - Current working context
4. **.claude/completed.txt** - What's already done
5. **TASKS.md** - Pending work items

### How to Update State
```bash
# After completing a feature
./scripts/update-state.sh "Completed API endpoints for /v1/runs"

# After making a decision
./scripts/log-decision.sh "Chose NATS over Redis because of built-in persistence"

# Before ending session
./scripts/save-context.sh
```

## 🧠 Context Recovery

### If Claude Forgets Previous Work

1. **Show the context files:**
```
"Please read these files to understand what we've built:
- HANDOFF.md (current state)
- DECISIONS.md (architectural choices)
- .claude/context.json (working memory)"
```

2. **Run verification:**
```
"Run `make verify` to see what's working"
```

3. **Check test status:**
```
"Run `npm test` and `go test ./...` to verify functionality"
```

### Key Information to Preserve

Always document in `.claude/context.json`:
```json
{
  "currentPhase": "2.1",
  "lastWorkingEndpoint": "/v1/runs",
  "blockers": ["Need LLM API key"],
  "criticalDecisions": {
    "database": "PostgreSQL with TimescaleDB",
    "messageQueue": "NATS JetStream",
    "orchestrator": "LangGraph",
    "primaryLLM": "Claude 3 Opus"
  },
  "dependencies": {
    "npm": ["@langchain/core", "zod", "sveltekit"],
    "go": ["gin", "pgx", "nats.go"],
    "rust": ["tokio", "serde", "arrow"]
  }
}
```

## 🔨 Common Tasks

### Adding a New Feature

1. **Check roadmap:**
```bash
grep "[ ]" ROADMAP.md | head -5  # Next 5 tasks
```

2. **Create feature branch:**
```bash
git checkout -b feature/milestone-X-phase-Y
```

3. **Update contracts first:**
- Edit `contracts/openapi.yaml`
- Update `contracts/shared/types.ts`
- Run `make validate-contracts`

4. **Implement with tests:**
```bash
# Write test first
touch tests/feature-X.test.ts

# Implement feature
# ...

# Verify
make test-feature
```

5. **Update documentation:**
- Update HANDOFF.md
- Log decision if needed
- Update context

### Fixing Integration Issues

1. **Check service health:**
```bash
./scripts/health-check.sh
```

2. **Review logs:**
```bash
docker-compose logs -f gateway
tail -f logs/orchestrator.log
```

3. **Test individual components:**
```bash
# Test API only
cd apps/api && go test ./...

# Test frontend only
cd apps/web && npm test

# Test orchestrator only
cd apps/orchestrator && npm test
```

### Debugging Connection Problems

Common issues and solutions:

| Problem | Check | Fix |
|---------|-------|-----|
| API not responding | `curl localhost:8080/health` | Check BACKEND_HTTP_ADDR in .env |
| SSE not streaming | Browser DevTools Network tab | Check CORS headers |
| DB connection failed | `psql $POSTGRES_DSN` | Verify Postgres is running |
| LLM timeout | Check API key validity | Set longer timeout or use mock |
| NATS not publishing | `nats stream ls` | Ensure NATS is running |

## 📝 Code Patterns to Follow

### API Endpoint Pattern (Go)
```go
// Always follow this structure
func (h *Handler) CreateRun(c *gin.Context) {
    // 1. Parse request
    var req CreateRunRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    
    // 2. Validate
    if err := req.Validate(); err != nil {
        c.JSON(422, gin.H{"error": err.Error()})
        return
    }
    
    // 3. Process
    result, err := h.service.Process(req)
    if err != nil {
        h.logger.Error("failed to process", zap.Error(err))
        c.JSON(500, gin.H{"error": "internal error"})
        return
    }
    
    // 4. Return
    c.JSON(200, result)
}
```

### Frontend Component Pattern (Svelte)
```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { api } from '$lib/api';
  import type { Run } from '$lib/types';
  
  export let runId: string;
  
  let run: Run | null = null;
  let error: string | null = null;
  
  onMount(async () => {
    try {
      run = await api.getRun(runId);
    } catch (e) {
      error = e.message;
    }
  });
</script>

{#if error}
  <div class="error">{error}</div>
{:else if run}
  <div class="run-details">...</div>
{:else}
  <div class="loading">Loading...</div>
{/if}
```

### Event Publishing Pattern
```typescript
// Always publish events with correlation ID
async function publishEvent(event: HelioxEvent) {
  const correlationId = event.trace_id;
  await nats.publish(
    `heliox.events.${correlationId}`,
    JSON.stringify(event)
  );
  logger.info(`Published event`, { 
    type: event.type, 
    correlationId 
  });
}
```

## 🚨 Critical Rules - NEVER BREAK THESE

1. **Never commit secrets** - Use .env and .gitignore
2. **Never skip tests** - Always run before committing
3. **Never change schema without migration** - Use numbered SQL files
4. **Never modify generated code** - Change the generator instead
5. **Never use different versions** - Check .tool-versions

## 📚 Resource Links

### Documentation
- LangGraph: https://langchain-ai.github.io/langgraph/
- Gin Framework: https://gin-gonic.com/docs/
- SvelteKit: https://kit.svelte.dev/docs
- NATS JetStream: https://docs.nats.io/jetstream

### Our Design Docs
- Architecture: See diagram in V21.ini lines 10-35
- API Spec: contracts/openapi.yaml
- Database: contracts/schemas/sql/
- Events: contracts/shared/events.ts

## 🆘 When Stuck

### If tests fail:
1. Check error message carefully
2. Look for recent changes: `git diff`
3. Revert if needed: `git checkout -- .`
4. Ask: "What changed since last working state?"

### If integration breaks:
1. Test each service individually
2. Check network connectivity
3. Verify environment variables
4. Review logs for each service

### If performance degrades:
1. Check database queries: EXPLAIN ANALYZE
2. Review network calls: too many?
3. Check for memory leaks: heap profile
4. Look for blocking operations

## 💡 Tips for Productive Sessions

1. **Start small** - One feature at a time
2. **Test often** - After each significant change
3. **Commit frequently** - Small, focused commits
4. **Document decisions** - Future you will thank you
5. **Keep context updated** - Save state before stopping