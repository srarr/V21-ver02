# Phase 1 Tasks - Heliox ATLAS v21

> Milestone 1: Foundation with Mocks
> Goal: Prove end-to-end flow works with all components connected

## 📊 Overall Progress: 10.6% (5/47 tasks)

---

## ✅ Phase 1.1: Infrastructure Setup [COMPLETED]
- [x] Project structure: `apps/{api,web,orchestrator}`, `contracts/`, `ops/`, `migrations/`
- [x] Supabase Local setup with Postgres migrations
- [x] OpenAPI contracts v0.1 (`contracts/openapi.yaml`)
- [x] Environment configuration with local-first flags
- [x] Rename migration to `001_init.sql`

---

## ✅ Phase 1.2: Core API (Go/Gin) [COMPLETED]

### Endpoints
- [x] `GET /healthz` → `{status: "ok"}` (200) ✅
- [x] `GET /version` → `{version: string, commit: string}` (200) ✅
- [x] `POST /v1/runs` → Create run, return `{runId: string}` (201) ✅
- [x] `GET /v1/runs/{id}` → `{status: string, lastSeq: int, summary: object}` (200) ✅
- [x] `GET /v1/runs/{id}/events` → SSE stream with sequential events ✅
- [x] `POST /v1/portfolio` → Save strategy, return 201 ✅
- [x] `GET /v1/portfolio` → List portfolio items (200) ✅

### Middleware & Security
- [x] CORS middleware with allowed origins ✅
- [x] Request/response logging with trace IDs ✅
- [x] JSON schema validation middleware ✅

### Testing
- [x] Unit tests: All endpoints return correct status codes ✅
- [x] SSE test: Connect → receive ≥3 events with seq: 1,2,3 ✅
- [x] Portfolio test: POST item → GET list contains saved item ✅
- [x] Schema validation: Invalid requests return 400 ✅
- [x] Integration: All endpoints pass schemathesis ✅

---

## 📝 Phase 1.3: Orchestrator (LangGraph) [PENDING]

### State Machine
- [ ] State transitions: `Architect → Synth → T0 → Pack`
- [ ] Each node emits events: `status` + `artifact`
- [ ] Event persistence to `run_events` with sequential `seq`

### Mock Nodes
- [ ] **Architect Mock**: Returns valid `blueprint` JSON
- [ ] **Synth Mock**: Returns array of `StrategyDSL` candidates
- [ ] **T0 Mock**: Returns backtest results
- [ ] **Pack Mock**: Returns HSP manifest

### Event System
- [ ] Event bus: In-memory queue
- [ ] SSE publisher: Streams events to clients
- [ ] Database logger: Persists every event
- [ ] Sequence guarantees: No gaps, no duplicates

---

## 🎨 Phase 1.4: Frontend (SvelteKit) [PENDING]

### Core Components
- [ ] **Chat Interface**: Input field + submit
- [ ] **SSE Client**: Auto-connects, handles reconnection
- [ ] **Timeline View**: Shows events by `seq`
- [ ] **Metrics Panel**: Displays mock backtest results
- [ ] **Portfolio Manager**: Save/list functionality

### UI/UX
- [ ] Loading states during execution
- [ ] Error handling for failed runs
- [ ] Responsive design (mobile-friendly)
- [ ] Real-time updates (no manual refresh)

---

## 🧪 Phase 1.5: Integration & Testing [PENDING]

### Test Suites
- [ ] **API Tests**: Postman/Jest collection
- [ ] **SSE Tests**: WebSocket client verification
- [ ] **Contract Tests**: Schemathesis
- [ ] **E2E Tests**: Playwright/Cypress
- [ ] **Performance Tests**: Mock flow ≤3s

### Infrastructure
- [ ] Docker Compose setup
- [ ] Makefile targets: `setup`, `dev`, `test`, `verify`
- [ ] CI pipeline

---

## 🛡️ Phase 1.6: UI Iteration Safety [PENDING]

- [ ] Create `apps/web/src/containers/` for state
- [ ] Create `apps/web/src/components/` for pure UI
- [ ] Implement Container/Presenter pattern

---

## 🚀 Next Actions

1. **Start Phase 1.2**: Bootstrap Go API
   ```bash
   mkdir -p apps/api/cmd/api
   cd apps/api
   go mod init github.com/heliox/atlas/api
   go get -u github.com/gin-gonic/gin
   ```

2. **Create main.go with /healthz endpoint**

3. **Test with curl**:
   ```bash
   curl http://localhost:8080/healthz
   ```

---

## 📈 Statistics

| Phase | Tasks | Completed | Progress |
|-------|-------|-----------|----------|
| 1.1   | 5     | 5         | 100%     |
| 1.2   | 12    | 0         | 0%       |
| 1.3   | 9     | 0         | 0%       |
| 1.4   | 9     | 0         | 0%       |
| 1.5   | 8     | 0         | 0%       |
| 1.6   | 3     | 0         | 0%       |
| **Total** | **47** | **5** | **10.6%** |

---

*Last Updated: 2024-08-28 03:00*
*Next Review: After completing 3 endpoints in Phase 1.2*