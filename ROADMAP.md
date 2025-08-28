# Heliox ATLAS v21 - Development Roadmap

## Overview
Building a complete Trading Strategy Platform from prompt to production deployment.
Each milestone builds upon the previous one. No skipping allowed.

## 🎯 Milestone 1: Foundation with Mocks (Week 1)
**Goal:** Prove end-to-end flow works with all components connected
**Invariants:** Contract-first, Local-first (no external providers), Schema-compliant mocks, Event ordering

### Phase 1.1: Infrastructure Setup ✅

#### Core Structure
- [x] Project structure: `apps/{api,web,orchestrator}`, `contracts/`, `ops/`, `migrations/`
- [x] Supabase Local setup with Postgres migrations
- [x] OpenAPI contracts v0.1 (`contracts/openapi.yaml`)
- [x] Environment configuration with local-first flags

#### Contract Files Required
- [x] `contracts/openapi.yaml` with complete Phase 1 endpoints ✅
- [x] `migrations/001_init.sql` with all required tables ✅
- [x] `contracts/fixtures/` with mock payloads ✅
- [x] `.env` with `DATA_REMOTE_PROVIDERS=disabled`, `TOKENS_LIMIT=10000`, `TIME_MS_LIMIT=60000` ✅

**DoD 1.1:**
- `supabase start` succeeds, `supabase status` shows active URL/KEY
- Migrations create tables: `runs`, `run_events`, `portfolio_items`, `strategies` (idempotent)
- `openapi.yaml` validates and passes smoke test with schemathesis
- Environment flags prevent external API calls

### Phase 1.2: Core API (Go/Gin) - Contract-First Implementation

#### Required Endpoints
- [x] `GET /healthz` → `{status: "ok"}` (200) ✅
- [x] `GET /version` → `{version: string, commit: string}` (200) ✅
- [x] `POST /v1/runs` → Create run, return `{runId: string}` (201) ✅
  - Request: `{prompt: string}`
  - Sets run status to PENDING→RUNNING
- [x] `GET /v1/runs/{id}` → `{status: string, lastSeq: int, summary: object}` (200) ✅
- [x] `GET /v1/runs/{id}/events` → SSE stream with sequential events ✅
  - Format: `event: {type}\ndata: {OrchestratorEvent JSON}\n\n`
- [x] `POST /v1/portfolio` → Save strategy, return 201 ✅
  - Request: `{id: string, name: string, strategy: object}`
- [x] `GET /v1/portfolio` → List portfolio items (200) ✅

#### Middleware & Security
- [x] CORS middleware with allowed origins ✅
- [x] Request/response logging with trace IDs ✅
- [x] JSON schema validation middleware ✅

**DoD 1.2:**
- Unit tests: All endpoints return correct status codes and schemas
- SSE test: Connect → receive ≥3 events with seq: 1,2,3 (no gaps)
- Portfolio test: POST item → GET list contains saved item
- Schema validation: Invalid requests return 400 with error details
- Integration: All endpoints pass schemathesis contract testing

### Phase 1.3: Orchestrator (LangGraph) - Schema-Compliant Mocks

#### State Machine Flow
- [x] State transitions: `Architect → Synth → T0 → Pack` (linear for Phase 1)
- [x] Each node emits events: `status` (start/progress) + `artifact` (results)
- [x] Event persistence: All events saved to `run_events` with sequential `seq`
- [x] Mock responses **must match production schemas** (from Phase 2/3 contracts)

#### Mock Node Implementations
- [x] **Architect Mock**: Returns valid `blueprint` JSON matching Phase 2.3 schema
  ```json
  {"blueprint": {"universe": ["XAUUSD"], "features": ["SMA","EMA"], "constraints": {"risk_bp": 50}}}
  ```
- [x] **Synth Mock**: Returns array of valid `StrategyDSL` candidates (Phase 2 schema)
- [x] **T0 Mock**: Returns backtest results with `equity`, `trades`, `metrics` (Phase 3 schema)
- [x] **Pack Mock**: Returns HSP manifest and download link

#### Event System
- [x] Event bus: In-memory queue for Phase 1 (NATS/Redis optional)
- [x] SSE publisher: Streams events to connected clients
- [x] Database logger: Persists every event to `run_events`
- [x] Sequence guarantees: No gaps, no duplicates, monotonic increase

**DoD 1.3:**
- Mock run produces event sequence: architect.status(1) → architect.artifact(2) → synth.status(3) → synth.artifact(4) → t0.status(5) → t0.artifact(6) → pack.artifact(7)
- Database `run_events` count matches SSE event count exactly
- All mock payloads validate against their respective schemas (ajv)
- Zero external API calls (verified by network monitoring/logs)
- Event replay: Database events → identical SSE stream

### Phase 1.4: Frontend (SvelteKit) - Complete UI Flow

#### Core Components
- [x] **Chat Interface**: Input field + submit → calls `POST /v1/runs`
- [x] **SSE Client**: Auto-connects to `/v1/runs/{id}/events`, handles reconnection
- [x] **Timeline View**: Shows events by `seq` with phase indicators (architect→synth→t0→pack)
- [x] **Metrics Panel**: Displays mock backtest results from `t0.artifact`
- [x] **Portfolio Manager**: Save button → `POST /v1/portfolio`, list view from `GET /v1/portfolio`

#### UI/UX Requirements
- [x] Loading states during orchestrator execution
- [x] Error handling for failed runs (error events)
- [x] Responsive design (mobile-friendly)
- [x] Real-time updates (no manual refresh needed)

**DoD 1.4:**
- Demo flow: "Create MA crossover strategy" → timeline progresses → mock metrics appear
- Save functionality: Click save → strategy appears in portfolio list
- SSE resilience: Page refresh during run → reconnects and shows current state
- Error handling: Mock error event → user sees error message in UI

### Phase 1.5: Integration & Testing - End-to-End Verification

#### Test Suite
- [x] **API Tests**: Postman/Jest collection for all endpoints
- [x] **SSE Tests**: WebSocket client verifies event ordering and format
- [x] **Contract Tests**: Schemathesis against OpenAPI spec
- [x] **E2E Tests**: Playwright/Cypress full user journey
- [x] **Performance Tests**: Mock flow completes in ≤3s

#### Integration Environment
- [x] Docker Compose: `api`, `web`, `supabase`, `minio` (optional)
- [x] Makefile targets: `setup`, `dev`, `test`, `verify`
- [x] CI pipeline: Contract validation → unit tests → integration tests

#### Verification Commands
```makefile
verify:
	schemathesis run contracts/openapi.yaml --base-url=http://localhost:8080
	go test ./apps/api/... -v
	npm test --workspace=apps/web
	playwright test tests/e2e/
```

**DoD 1.5:**
- `make verify` passes all tests (schemathesis, unit, integration, e2e)
- Mock end-to-end flow: prompt → results in ≤3s on dev machine
- All components start cleanly with `make dev`
- Zero external network calls during test run (verified)

### Phase 1.6: UI Iteration Safety (UI-only track)
**Goal:** Separate UI from business logic to enable unlimited UI redesigns without breaking data flow/events

#### Phase 1.6.1: Container/Presenter Split
- [x] Create `apps/web/src/containers/` for state + side effects (API, SSE)
- [x] Create `apps/web/src/components/` for pure UI rendering (props only)
- [x] **ChatContainer**: Manages prompt state, API calls, SSE connections
- [x] **ChatPresenter**: Renders UI, receives onSubmit/onChange props
- [x] **TimelineContainer**: Handles events state, filtering, updates
- [x] **TimelinePresenter**: Pure visualization component
- [x] **PortfolioContainer**: Manages save/load/list operations
- [x] **PortfolioPresenter**: UI for strategy cards, forms, lists

**DoD 1.6.1:**
- All business logic moved to containers (no useState/useEffect in presenters)
- Presenters receive all data via props (no direct API calls)
- Type definitions for all presenter prop interfaces

#### Phase 1.6.2: API Client Module (Single Source of Truth)
- [x] `apps/web/src/services/api.ts` - Centralized API methods
  ```typescript
  export const api = {
    createRun: (prompt: string) => Promise<{runId: string}>
    getRun: (id: string) => Promise<RunStatus>
    streamEvents: (runId: string) => EventSource
    saveStrategy: (strategy: Strategy) => Promise<void>
    listStrategies: () => Promise<Strategy[]>
  }
  ```
- [x] Auto-retry logic for network failures
- [x] Request/response logging with trace IDs
- [x] TypeScript interfaces for all request/response types

**DoD 1.6.2:**
- No direct `fetch()` calls in components (all via api.ts)
- All endpoints centralized with consistent error handling
- Request timeout and retry policies implemented

#### Phase 1.6.3: Business Hooks
- [x] `hooks/useStrategyRun.ts`: Complete strategy execution flow
  ```typescript
  export const useStrategyRun = () => {
    const [status, setStatus] = useState<RunStatus>('idle')
    const [events, setEvents] = useState<OrchestratorEvent[]>([])
    const [error, setError] = useState<string | null>(null)
    
    const startRun = async (prompt: string) => { /* SSE setup */ }
    const stopRun = () => { /* cleanup */ }
    
    return { status, events, error, startRun, stopRun }
  }
  ```
- [x] `hooks/usePortfolio.ts`: Strategy save/load operations
- [x] `hooks/useSSE.ts`: Reusable SSE connection with reconnect
- [x] All hooks handle cleanup, error states, loading states

**DoD 1.6.3:**
- Containers use hooks exclusively (no direct API calls)
- All hooks have proper cleanup (prevent memory leaks)
- Error boundaries implemented for hook failures

#### Phase 1.6.4: Type Safety & Bindings
- [x] TypeScript interfaces for all presenter props:
  ```typescript
  interface ChatPresenterProps {
    prompt: string
    onChange: (value: string) => void
    onSubmit: (prompt: string) => Promise<void>
    loading: boolean
    error?: string
  }
  ```
- [x] `contracts/ui-bindings.json` - Required UI elements and endpoints:
  ```json
  {
    "chat": {
      "inputId": "prompt-input",
      "submitId": "submit-button",
      "required_props": ["value", "onChange", "onSubmit"],
      "api_endpoint": "/v1/runs",
      "sse_endpoint": "/v1/runs/{id}/events"
    }
  }
  ```
- [x] Runtime prop validation in development mode
- [x] ESLint rules preventing direct API usage in presenters

**DoD 1.6.4:**
- All presenters have TypeScript interfaces
- Prop validation catches missing handlers
- ui-bindings.json covers all critical UI elements

#### Phase 1.6.5: SSE Resilience
- [x] SSE wrapper with automatic retry/backoff:
  ```typescript
  export const createResilientSSE = (url: string) => {
    // Auto-reconnect with exponential backoff
    // Duplicate event filtering
    // Proper cleanup on component unmount
  }
  ```
- [x] Sequence monotonic checking (seq: 1,2,3... no gaps)
- [x] Connection state monitoring (connecting/open/error/closed)
- [x] Graceful degradation when SSE unavailable

**DoD 1.6.5:**
- SSE connections survive page refresh
- Network interruptions automatically recover
- Event sequence validation prevents duplicates

#### Phase 1.6.6: UI Smoke Tests & Checklist
- [x] `tests/ui/connection.spec.ts` - Connection verification:
  ```typescript
  test('Chat connection integrity', async () => {
    await expect(api.healthCheck()).resolves.toMatchObject({status: 'ok'})
    await expect(api.createRun('test')).resolves.toHaveProperty('runId')
    const sse = api.streamEvents('test-run')
    await expect(sse).toReceiveEvents(3) // status, artifact, complete
  })
  ```
- [x] **Chat Module Checklist** (must pass before UI changes):
  - [x] Input has value binding
  - [x] Input has onChange handler
  - [x] Form has onSubmit handler + preventDefault
  - [x] API endpoint correct (/v1/runs)
  - [x] SSE endpoint string correct
  - [x] Error/loading states display
  - [x] Timeline updates on events
  - [x] SSE cleanup on unmount

**DoD 1.6.6:**
- All smoke tests automated in CI
- Checklist prevents breaking changes
- Tests run in <5s for quick feedback

#### Phase 1.6.7: Storybook & Snapshots (Optional)
- [x] Storybook setup for presenter components:
  ```bash
  npm run storybook  # Isolated UI development
  ```
- [x] Stories for Chat, Timeline, Portfolio presenters
- [x] Mock data providers for Storybook
- [x] `make snapshot-ui` - Backup UI state before changes:
  ```bash
  snapshot-ui:
  	@node ops/scripts/snapshot-ui.js
  	@echo "✅ UI snapshot saved with timestamp"
  ```

**DoD 1.6.7:**
- Storybook shows main presenters working
- UI snapshots created before major changes
- Mock mode allows UI development without backend

#### Phase 1.6.8: Mock Mode & Runtime Flags
- [x] Environment flag: `UI_MOCK=on` for fixture-based development
- [x] Mock implementations of all API methods using fixtures
- [x] Runtime switching between mock/real without code changes:
  ```typescript
  const api = process.env.UI_MOCK === 'on' ? mockApi : realApi
  ```
- [x] Fixture data matches production schemas exactly
- [x] Mock mode preserves all UI interactions and states

**DoD 1.6.8:**
- `UI_MOCK=on` enables complete offline UI development
- Mock responses validate against OpenAPI schemas
- Switch modes without component changes

### Make Targets (Phase 1.6)
```makefile
.PHONY: test-ui-connections snapshot-ui storybook

test-ui-connections:
	@echo "🔍 Testing UI connections..."
	@curl -s http://localhost:8080/healthz | grep "ok"
	@npm run test:e2e -- --grep "chat submission"
	@npm run test:e2e -- --grep "SSE event sequence"
	@echo "✅ UI connections intact"

snapshot-ui:
	@echo "📸 Creating UI snapshot..."
	@node ops/scripts/snapshot-ui.js
	@echo "✅ UI snapshot saved with timestamp"

storybook:
	@npm run storybook

ui-checklist:
	@echo "📋 Running Chat Module Checklist..."
	@node tests/ui/checklist.js
	@echo "✅ All UI bindings verified"
```

**DoD (Phase 1.6 Complete):**
- UI uses only `api.ts` + hooks (no direct fetch in presenters)
- Chat presenter redesigned → event handlers and state binding still work
- `make test-ui-connections` passes all verification
- `UI_MOCK=on` enables fixture-based development
- Storybook displays main presenter components
- TypeScript prevents accidental API usage in presenters

**Success Criteria (Phase 1.6):**
- **UI Freedom**: Redesign Chat/Timeline/Portfolio UI completely without breaking functionality
- **Connection Safety**: Change UI 3 times → API calls and SSE streaming still work perfectly
- **Mock Development**: Switch to `UI_MOCK=on` → full UI functionality with fixtures
- **Type Safety**: TypeScript catches missing props/handlers during UI changes
- **Test Coverage**: All critical UI connections automatically verified

### Required Contracts & Schemas

#### OpenAPI v0.1 (Core Endpoints)
```yaml
openapi: 3.0.3
info: { title: ATLAS API, version: 0.1.0 }
paths:
  /healthz:
    get:
      responses: { "200": { description: OK, content: { application/json: { schema: { type: object, properties: { status: { type: string } } } } } } }
  
  /v1/runs:
    post:
      requestBody: { required: true, content: { application/json: { schema: { type: object, required: [prompt], properties: { prompt: { type: string } } } } } }
      responses: { "201": { description: Created, content: { application/json: { schema: { type: object, required: [runId], properties: { runId: { type: string } } } } } } }

  /v1/runs/{id}/events:
    get:
      parameters: [{ in: path, name: id, required: true, schema: { type: string } }]
      responses: { "200": { description: SSE Stream, content: { text/event-stream: { schema: { type: string } } } } }

components:
  schemas:
    OrchestratorEvent:
      type: object
      required: [runId, seq, phase, type, ts, payload]
      properties:
        runId: { type: string }
        seq: { type: integer }
        phase: { type: string, enum: [architect, synth, t0, pack] }
        type: { type: string, enum: [status, artifact, error] }
        ts: { type: string, format: date-time }
        payload: { type: object, additionalProperties: true }
```

#### SQL Schema (migrations/001_init.sql)
```sql
create table if not exists runs (
  id uuid primary key default gen_random_uuid(),
  status text not null check (status in ('PENDING','RUNNING','FAILED','COMPLETED')),
  prompt text,
  started_at timestamptz default now(),
  finished_at timestamptz
);

create table if not exists run_events (
  run_id uuid references runs(id) on delete cascade,
  seq int not null,
  phase text not null,
  type text not null check (type in ('status','artifact','error')),
  ts timestamptz not null default now(),
  payload jsonb not null,
  primary key (run_id, seq)
);

create table if not exists portfolio_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  strategy jsonb not null,
  created_at timestamptz default now()
);

create table if not exists strategies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  dsl jsonb not null,
  created_at timestamptz default now()
);
```

#### SSE Event Examples
```
event: status
data: {"runId":"b6c...9f","seq":1,"phase":"architect","type":"status","ts":"2025-08-27T10:15:33.001Z","payload":{"msg":"starting blueprint analysis"}}

event: artifact
data: {"runId":"b6c...9f","seq":2,"phase":"architect","type":"artifact","ts":"2025-08-27T10:15:33.120Z","payload":{"blueprint":{"universe":["XAUUSD"],"features":["SMA","EMA"],"constraints":{"risk_bp":50}}}}
```

### Success Criteria (Milestone 1 - Updated)
- **Contract Compliance**: All endpoints match OpenAPI spec, pass schemathesis
- **Event Ordering**: SSE events maintain strict sequential ordering (no gaps)
- **Schema Consistency**: Mock payloads match production schemas (no drift)
- **Local-First**: Zero external API calls, all data synthetic/mocked
- **Performance**: Mock end-to-end flow completes in ≤3s
- **Persistence**: All events stored in database, queryable/replayable
- **User Experience**: "Create MA crossover strategy" → sees timeline → saves to portfolio
- **Test Coverage**: `make verify` passes all contract, unit, integration, e2e tests
- **UI Safety**: Phase 1.6 enables unlimited UI redesigns without breaking backend connections
- **Mock Development**: `UI_MOCK=on` allows complete offline UI development with fixtures
- **Type Safety**: TypeScript prevents accidental removal of critical props/handlers
- **Connection Integrity**: `make test-ui-connections` verifies all critical UI → API bindings

## 🚀 Milestone 2: Real LLM Integration (Week 2)
**Goal:** แทนที่ mocks ด้วย LLM จริง โดยยังคุมได้ด้วยสัญญาและการตรวจสอบที่เคร่งครัด  
**Invariants:** Contract-first, Local-first flags, Deterministic (mock/stub ได้), Budget/Checkpoint/Events ครอบทุก node

### Phase 2.1: LLM Service (Provider Abstraction + Routing + Validation)

#### Phase 2.1.1: Provider Abstraction (Contracts)
- [ ] Interface เดียวสำหรับผู้ให้บริการ: {model_id, input{system,user}, tools?, temperature, max_tokens, seed?}
- [ ] Normalized output: {model_id, content, finish_reason, usage{prompt,completion,total}}
- [ ] ENV: ANTHROPIC_API_KEY?, OPENAI_API_KEY?, OLLAMA_HOST? (optional)
- [ ] Model Allowlist (config): anthropic[*], openai[*], ollama[*] (ระบุชื่อรุ่นเฉพาะ)
- [ ] Timeouts: connect/read (เช่น 10s/60s), circuit-breaker

**DoD:**
- Unit tests (stubbed clients) ครอบคลุม finish_reason/timeout/429/5xx
- Fault injection (ชะงัก/คืน JSON เพี้ยน/ขึ้นโควต้า) ผ่านการกู้คืนที่คาดไว้

#### Phase 2.1.2: Routing & Fallback Policy
- [ ] Routing policy: preferred → fallback → local (ollama) ตาม model_allowlist
- [ ] Budget Guard hook (รอบๆ infer() ทุกครั้ง) บันทึก usage/token/time
- [ ] Retries: backoff (เฉพาะ 429/5xx) + JSON-repair loop ≤ 1 ครั้ง
- [ ] Observability: log semantic fields (model, latency_ms, tokens, repair_attempts)

**DoD:**
- Latency p95 (architect/synth เดี่ยว) ≤ 6s ที่ 2k tokens input
- Budget เก็บ usage ลงตาราง run_budget ทุกครั้ง
- Fallback ทำงานจริงเมื่อ primary ล้มเหลว

#### Phase 2.1.3: Prompt Template Registry
- [ ] Template per node: architect, synth, qc_planner, formal_verifier, style_qa, gatekeeper
- [ ] Template spec (YAML/JSON): id, version, system, user_placeholders[], stop[], output_schema_ref
- [ ] Template loader + checksum (กัน drift)
- [ ] Snapshot template_id@version ใน run_events (artifact meta)

**DoD:**
- Template มี checksum ตรงกับที่ยิงจริง (audit)
- เปลี่ยน template แล้ว test snapshot ต่างกันตาม version

#### Phase 2.1.4: Response Parsing & JSON Repair
- [ ] Strict JSON parse → validate กับ JSON Schema ตาม node
- [ ] JSON-repair รอบเดียว: prompt ซ่อมแซม (ถ้ายัง fail → error event)
- [ ] Output shape ต้องผ่าน zod/ajv และไม่มี field เกิน

**DoD:**
- 200 เคส fuzz → 0 crash, อัตรา repair สำเร็จ ≥ 95% ในกรณีผิดเล็กน้อย
- Invalid JSON → ได้ error event พร้อมสาเหตุชัดเจน

#### Phase 2.1.5: Safety & Injection Guard
- [ ] Mask secrets ใน prompt (ENV/keys)
- [ ] Disable tool-use (ถ้าไม่ต้องใช้)
- [ ] แยก "user content" ออกจาก "system guardrails" ชัดเจน
- [ ] Heuristic ตรวจ prompt injection (ลิสต์คำสั่งต้องห้าม) → เตือน/จำกัด

**DoD:**
- ชุดเทส prompt-injection 20 เคส → ไม่มีข้อมูลลับรั่ว / policy ลัดขั้นตอน

### Phase 2.2: Strategy DSL (Grammar/Schema/IR/Static Checks)

#### Phase 2.2.1: DSL Schema & Versioning
- [ ] JSON Schema: StrategyDSL v0.1 (with $id + $schema + version)
- [ ] Required fields: id, name, timeframe(enum:1m,5m,15m,1h,4h,1d), rules[], params{}, metadata
- [ ] Rule item: { if:string, then:enum(buy,sell,close,hold) }
- [ ] Params: numeric-only; bounds (min/max) ต่อคีย์ที่รู้จัก
- [ ] Metadata: { tags?:string[], notes?:string }
- [ ] Versioning policy: bump minor เมื่อเพิ่มฟิลด์ optional; major เมื่อเปลี่ยน semantics

**DoD:**
- ajv + zod validators ผ่านทุก fixture
- Backward-compat tests ระหว่าง v0.1 → v0.1.x

#### Phase 2.2.2: Expression Grammar (IF side)
- [ ] Mini-expression language (EBNF ย่อ):
      expr := or_expr
      or_expr := and_expr (" or " and_expr)*
      and_expr := unary_expr (" and " unary_expr)*
      unary_expr := "not " unary_expr | primary
      primary := fun | "(" expr ")"
      fun := IDENT "(" args? ")"
      args := expr ("," expr)*
- [ ] Indicator whitelist: ma, ema, rsi, atr, bbands, slope, crossover(a,b), crossunder(a,b)
- [ ] Type system: numeric vs boolean; fun signatures ตายตัว
- [ ] Disallow lookahead: ไม่มีฟังก์ชันอ้างค่าอนาคต/shift < 0

**DoD:**
- Parser property-tests (invalid tokens → error ที่ loc ถูกต้อง)
- ฟังก์ชันนอก whitelist → reject พร้อมโค้ด error

#### Phase 2.2.3: IR (Intermediate Representation)
- [ ] IR structs (language-agnostic) สำหรับ rules/params/timeframe
- [ ] Lowering pipeline: DSL(JSON) → IR → Engine-call
- [ ] Const folding / simplification (เช่น not(not x) → x)
- [ ] Deterministic hashing (IR → content-hash) เพื่อ cache/backtest reuse

**DoD:**
- DSL เดียวกัน → IR hash เดียวกัน (stable)
- Fields reorder ใน JSON → IR hash ไม่เปลี่ยน

#### Phase 2.2.4: Static Checks & Semantics
- [ ] Safety: no-lookahead, bounded risk (ต้องมี sizing/stop เงื่อนไข), termination conditions
- [ ] Consistency: ขัดแย้งกันเอง (เช่น buy+sell พร้อมกัน) → error
- [ ] Cooldown bars ≥ 1 (ถ้าระบุ)
- [ ] Timeframe compatibility (เช่น indicator window ≤ series length)

**DoD:**
- ชุดเคส static-check 50 ตัวอย่าง → error codes แม่นยำ (code,msg,loc)

#### Phase 2.2.5: Error Taxonomy & Developer UX
- [ ] Error codes: DSL_SCHEMA_INVALID, DSL_PARSE_ERROR, DSL_STATIC_FAIL, DSL_UNSUPPORTED_FUN, DSL_PARAM_OUT_OF_RANGE
- [ ] แต่ละ error ต้องมี: code, message, loc(path/index), hints
- [ ] Mapping error → user-facing events (ใน orchestrator)

**DoD:**
- devX test: แก้ DSL ตาม hint แล้วผ่านใน ≤2 รอบ (p95)

#### Phase 2.2.6: Fixtures & Fuzz
- [ ] Fixtures อย่างน้อย 8 ตัว (trend, mean-revert, breakout, overfit-trap, invalid cases)
- [ ] Fuzz 1k เคส/วัน: assert ไม่ crash + ข้อผิดพลาดเข้า taxonomy เดิม
- [ ] Golden fixtures ผูกกับ seed เดียวกันสำหรับ CI

**DoD:**
- Fuzz ผ่าน, ไม่มี unclassified error
- Golden snapshots เสถียรบน PR ต่อเนื่อง

### Phase 2.3: Enhanced Orchestrator
**Goal:** สร้าง Orchestrator ที่ทำงานจริง มี Architect + Synth node พร้อม Budget Guard, Checkpointer, และ Event Log

#### Phase 2.3.1: Contracts & Schemas
- [ ] Update OpenAPI with endpoints: /api/v1/orch/architect, /api/v1/orch/synth, /api/v1/runs/{id}/events (SSE)
- [ ] Add JSON Schemas: OrchestratorEvent, ArchitectResult, SynthResult
- [ ] Add StrategyDSL reference in SynthResult
- [ ] DoD: Schemathesis passes all endpoints

#### Phase 2.3.2: Database Layer
- [ ] Add Postgres tables: runs, run_events, checkpoints, run_budget
- [ ] Ensure idempotent migrations
- [ ] Seed .env with TOKENS_LIMIT, TIME_MS_LIMIT
- [ ] DoD: Insert/select smoke tests succeed

#### Phase 2.3.3: Budget Guard
- [ ] Implement guard wrapper for LLM calls
- [ ] Track tokens/time per run
- [ ] Abort with error event if over limit
- [ ] Attach budget snapshot to all events
- [ ] DoD: Budget exceed test → emits error + stops run

#### Phase 2.3.4: Checkpointer
- [ ] Split Architect/Synth into sub-steps: architect.parse_req, architect.llm_call, architect.emit_artifact, synth.prepare_blueprint, synth.llm_iter, synth.emit_candidates
- [ ] Save state jsonb in checkpoints per step
- [ ] Resume run from last checkpoint
- [ ] DoD: Kill process mid-step → resume works

#### Phase 2.3.5: Event System
- [ ] SSE endpoint streaming events
- [ ] Seq strictly increasing
- [ ] Emit types: status, artifact, error
- [ ] Store events in run_events
- [ ] DoD: Replay full run events via SSE and DB match

#### Phase 2.3.6: Architect Node
- [ ] System prompt: Convert NL → blueprint JSON (universe, features, constraints, notes)
- [ ] Validate JSON vs blueprint schema
- [ ] Repair once if schema invalid, else emit error
- [ ] Store artifact in MinIO
- [ ] DoD: Given prompt → returns valid blueprint + events

#### Phase 2.3.7: Synth Node (CEGIS-Light)
- [ ] Loop generate N (3–5) candidates
- [ ] Validate each with StrategyDSL schema
- [ ] Deduplicate by rule similarity (Jaccard < 0.6)
- [ ] Emit status per iteration
- [ ] Emit artifact with final strategies[]
- [ ] DoD: ≥3 distinct valid candidates, persisted in Supabase

#### Phase 2.3.8: API Flow
- [ ] POST /orch/architect: parse_req → llm_call → emit_artifact
- [ ] POST /orch/synth: prepare_blueprint → llm_iter → emit_candidates
- [ ] Events streamed live via /runs/{id}/events
- [ ] DoD: Full run NL → Blueprint → Candidates → Events visible

#### Phase 2.3.9: Testing & DoD
- [ ] Contracts: Schemathesis suite green
- [ ] Budget: exceed limit triggers error event
- [ ] Checkpoint: resume mid-architect works
- [ ] Events: seq order + replay verified
- [ ] Determinism: fixed seed → identical blueprint/candidates
- [ ] No external data provider usage in Phase 2–7

**DoD (Milestone 2 รวม):**
- Schemathesis ผ่านทุก endpoint ที่เกี่ยวกับ orchestrator/LLM
- ajv+zod ผ่านทุก Strategy DSL fixture (valid+invalid)
- Routing/fallback ถูกต้องเมื่อ primary ล้มเหลว
- Budget Guard ทำงานจริง (เก็บ usage + stop เมื่อเกิน)
- Deterministic บน mock seed (blueprint/candidates ผลซ้ำได้)
- Prompt-injection harness ผ่าน (ไม่มีข้อมูลลับรั่ว/โดนชักจูงให้ปิด guardrails)

**Success Criteria:**
- Natural language prompt → Valid blueprint JSON
- ≥3 valid distinct candidate strategies produced
- Events stream live with seq consistency
- Budget respected (no run exceeding tokens/time limits)
- Runs reproducible with same seed + model

## 📊 Milestone 3: Synthetic Backtest Engine (Week 3)
**Goal:** Backtesting with simulated price environments (no historical data); deterministic, fast, contract-first.
**Invariants:** Contract-first, Local-first, Deterministic (cacheable), Budget Guards, Zero external data dependencies

### Storage Architecture
**Object Storage (MinIO/S3-compatible):**
```
s3://atlas/
  scenarios/{scenario_id}/{scenario_hash}/
    dataset.parquet
    manifest.json
  runs/{run_id}/
    blueprint.json
    strategies.json
    equity.npy
    trades.jsonl
    metrics.json
```

**Supabase/Postgres Tables:**
- `scenarios(id, family, params_json, seed, timeframe, scenario_hash, object_ref, created_at)`
- `runs(id, status, started_at, finished_at, scenario_id, cache_key)`
- `run_results(run_id, metrics_json, equity_ref, trades_ref, used_cache, created_at)`
- `run_events(run_id, seq, phase, type, ts, payload_json)` (for SSE/replay)

**Content-hash key:** `scenario_hash = sha256(canonical_json(ScenarioDSL + seed + timeframe))`

### Phase 3.1: Market Scenario Generator

#### Phase 3.1.1: Scenario DSL v0.1 (JSON Schema)
- [ ] Required fields: `id:string, version:string("0.1"), timeframe:enum(1m,5m,15m,1h,4h,1d), duration_bars:int(≥100), seed:int, family:enum(trend, mean_revert, vol_cluster, shock_mix), params:object, volume_model:enum(const, lognormal)`
- [ ] Family params (minimal):
  - `trend: { drift: number(bps/bar), sigma: number(bps/sqrt(bar)) }`
  - `mean_revert: { kappa:number>0, theta:number>0, sigma:number>0 }` (OU on returns)
  - `vol_cluster: { omega:number>0, alpha:number∈[0,1), beta:number∈[0,1), mu:number }` (GARCH-like)
  - `shock_mix: { p_jump:number∈[0,1], jump_mu:number(bps), jump_sigma:number(bps) }`
- [ ] Schema validation with ajv

**DoD:** Schema exists + validates 6 fixture files (trend↑, trend↓, mean_revert, vol_cluster_low, vol_cluster_high, shocky)

#### Phase 3.1.2: Synthetic Generator Algorithms
- [ ] **trend** → GBM on price or normal returns with drift+sigma
- [ ] **mean_revert** → Ornstein-Uhlenbeck on returns; clamp to avoid extreme drift
- [ ] **vol_cluster** → GARCH-like returns; r_t = σ_t * z_t
- [ ] **shock_mix** → Bernoulli jumps + price gaps
- [ ] Build OHLCV from close path (envelope high/low; volume via model)
- [ ] Guards: price>0; finite; no NaN/Inf

**DoD:** Same DSL+seed → identical first/last 10 bars; all prices > 0; no NaN/Inf across parameter grid

#### Phase 3.1.3: Determinism & Storage
- [ ] PRNG seeded (PCG/Xoshiro) for reproducibility
- [ ] Manifest.json: `{scenario_id, scenario_hash, engine_ver, bars, min/max, seed, generated_at}`
- [ ] MinIO path: `scenarios/{id}/{scenario_hash}/dataset.parquet + manifest.json`
- [ ] Content-hash = SHA256(canonical_json(params+seed+timeframe))

**DoD:** Same (DSL+seed) → identical dataset hash; manifest present; MinIO objects exist

#### Phase 3.1.4: Validation Hooks
- [ ] ajv validate Scenario DSL
- [ ] Property checks: price>0, |ΔlogP| < 25σ (outlier guard), bars == duration_bars
- [ ] CI pipeline fails if any scenario fixture lacks MinIO object

**DoD:** Property tests pass; ajv validation green on all fixtures

### Phase 3.2: Rust Engine Core (Synthetic Mode)

#### Phase 3.2.1: Ingestion
- [ ] Accept Scenario DSL inline OR scenario_ref (MinIO path)
- [ ] Normalize to columnar OHLCV (time, open, high, low, close, volume)
- [ ] Load from parquet efficiently

**DoD:** Both inline and scenario_ref work; parquet loading under 100ms for 10k bars

#### Phase 3.2.2: Execution Simulator
- [ ] Order types: market, limit, stop
- [ ] Fill model: bar-close for market; high/low cross for limit/stop
- [ ] Slippage (bps) = base_bps + k_vol * rolling_vol
- [ ] Fee (bps) per trade; latency: bar_delay:int

**DoD:** Limit fills only if low≤limit≤high; stop triggers on cross; no fills without price touch

#### Phase 3.2.3: Portfolio & Accounting
- [ ] Positions: qty, avg_price, PnL realized/unrealized
- [ ] Cash ledger; equity curve; trade log (time, side, qty, px, fee, slippage)
- [ ] Guards: no negative shares; cash ≥ −max_margin (if margin disabled → cash≥0)

**DoD:** Inventory conservation; cash+position_value == equity; zero-rule strategy → zero trades

#### Phase 3.2.4: REST Endpoints (Go API binding)
- [ ] `POST /api/v1/engine/t0` (1k bars scenario; quick ≤5s)
- [ ] `POST /api/v1/engine/t1` (10k–50k bars scenario; full ≤30s)
- [ ] Request: `{ strategy: StrategyDSL, scenario: ScenarioDSL|ref, fees_bps, slippage_bps, bar_delay, initial_cash }`
- [ ] Response: `{ equity: number[], trades: Trade[], metrics: Metrics, cache_key, used_cache: bool }`

**DoD:** Both endpoints return 200 + schema match; latency under budgets

#### Phase 3.2.5: Deterministic Caching
- [ ] Result signature = HASH(IR(strategy) + scenario_hash + fees/slippage/delay + engine_ver)
- [ ] If signature hit → serve cached; else compute & persist
- [ ] Cache hit rate ≥90% on repeat tests

**DoD:** Same signature returns used_cache=true; time reduces ≥80% on cache hit

#### Phase 3.2.6: Performance Budgets
- [ ] T0: ≤5s @ 1k bars; T1: ≤30s @ 50k bars (dev CPU)
- [ ] Memory footprint bounded (< 200MB on T1 dev run)

**DoD:** Latency benchmarks pass; memory usage within bounds

### Phase 3.3: Risk Metrics & Stress Tests

#### Phase 3.3.1: Core Metrics
- [ ] **Sharpe** = mean(ret)/std(ret) * sqrt(252*bars_per_day_factor)
- [ ] **Sortino** = mean(pos_ret)/std(neg_ret) * sqrt(252*factor)
- [ ] **MaxDrawdown**: max over equity peak-to-trough
- [ ] **Win rate, Profit factor**
- [ ] Numerical tolerances: abs_err ≤ 1e-9 (double precision)

**DoD:** Metrics match golden CSV within tolerances; no NaN outputs

#### Phase 3.3.2: Stress Metrics
- [ ] **Tail-loss exposure**: P5 of daily returns; avg of worst 1%
- [ ] **Time-to-recovery**: bars from last equity peak to recovery

**DoD:** Stress metrics computed for all test runs; reasonable values

#### Phase 3.3.3: Monte Carlo (Synthetic Resampling)
- [ ] Block bootstrap on returns (block=20–60 bars) for N paths (N configurable)
- [ ] Return percentile metrics: Sharpe_p5, MDD_p95, PF_p5
- [ ] Stable across seeds (drift ≤ 0.1%)

**DoD:** MC produces stable percentiles; outputs not NaN; monotone expectations hold

#### Phase 3.3.4: Walk-forward (Synthetic Segments)
- [ ] K contiguous splits (train/test); re-eval params if strategy supports
- [ ] Report stability: variance of metrics across folds

**DoD:** Walk-forward reports K folds with all metrics present; no NaN

### Testing & Verification Framework

#### Unit Tests
**Rust (engine/generator/metrics):**
- `generator_trend_deterministic`: same DSL+seed → same hash + identical first/last 10 bars
- `engine_fill_rules`: limit fill only if low≤limit≤high; stop triggers on cross
- `accounting_conservation`: cash+position_value == equity; no negative shares
- `metrics_parity`: Sharpe/MDD/Sortino vs golden within 1e-9

**Go (API/SSE):**
- `/engine/t0` and `/engine/t1` return 200 + schema match
- Cache hit on second identical request (used_cache=true)
- SSE events preserve seq order (smoke test)

#### Property Tests
- **Generator**: prices > 0; |log returns| bounded; no NaN/Inf across params grid
- **Engine**: zero-rule strategy → zero trades; buy-only rule → no negative qty
- **Metrics**: constant equity → Sharpe=0, MDD=0

#### Integration Tests
- **T0**: Strategy DSL (MA crossover) + scenario(trend↑, σ=mid) → equity increasing; trades > 0
- **T1**: same strategy + vol_cluster_high → larger drawdown than vol_cluster_low
- **MC**: block bootstrap N=100 → outputs Sharpe_p5, MDD_p95 not NaN, monotone expectations hold

#### Performance/Determinism
- Benchmark T0/T1; assert under targets
- **Determinism**: same seed → identical equity & trades (byte-equal) across 3 runs

### Make Targets & Fixtures

```makefile
.PHONY: gen-scenarios test-engine verify

gen-scenarios:
	python ops/scripts/gen_scenarios.py contracts/fixtures/scenarios/ s3://atlas/scenarios/

test-engine:
	go test ./apps/api/... -run Engine
	cargo test -p atlas_engine

verify:
	ajv -s contracts/schemas/json/scenario_dsl.schema.json -d 'contracts/fixtures/scenarios/*.json'
	make test-engine
	schemathesis run contracts/openapi.yaml --base-url=http://localhost:8080 -E '/api/v1/engine/t0' -E '/api/v1/engine/t1'
```

#### Required Fixtures
- `scenario_trend_up_mid.json`
- `scenario_trend_down_high.json`
- `scenario_mean_revert.json`
- `scenario_vol_cluster_low.json`
- `scenario_vol_cluster_high.json`
- `scenario_shocky.json`
- `strategy_ma_crossover.json` (valid)
- `strategy_invalid_lookahead.json` (invalid; must be rejected)

### Technical Requirements
- **Canonical JSON encoder** (sorted keys, no whitespace) → stable hashing
- **Seed registry** (record seed per run) → CI can reproduce
- **Version stamps** (engine_ver, schema_ver) → included in cache key
- **Double precision** throughout metrics → no premature float optimization
- **No global mutable state** in Rust → dependency injection/context pattern

### Success Criteria (Milestone 3)
- ≥5 scenario families available; each fixture deterministic (hash-stable)
- T0 ≤5s (1k bars), T1 ≤30s (50k bars) on dev CPU
- Engine outputs deterministic, cache works; equity/trades stable across runs
- Metrics consistent within tolerances; MC/Walk-forward summaries emitted
- **Zero dependency on external historical data providers**
- All generated datasets written to MinIO with manifest + content-hash
- CI pipeline fails if schema validation or cache tests fail

## 💼 Milestone 4: Portfolio Management (Week 4)
**Goal:** Multi-strategy portfolio capabilities

### Phase 4.1: Portfolio Service
- [ ] Strategy versioning
- [ ] Performance tracking
- [ ] Correlation analysis
- [ ] Portfolio optimization
- [ ] Risk budgeting

### Phase 4.2: HSP Package System
- [ ] Strategy serialization format
- [ ] Metadata & manifests
- [ ] Compression (ZSTD)
- [ ] Digital signatures
- [ ] Import/export functionality

### Phase 4.3: Monitoring Dashboard
- [ ] Real-time metrics
- [ ] Performance charts
- [ ] Risk indicators
- [ ] Alert system

**Success Criteria:**
- Manage 10+ strategies simultaneously
- Track performance over time
- Export/import strategy packages

## 🏦 Milestone 5: Broker Integration (Week 5)
**Goal:** Connect to real trading venues

### Phase 5.1: Paper Trading
- [ ] In-memory order book
- [ ] Realistic slippage model
- [ ] Market hours enforcement
- [ ] Corporate actions handling

### Phase 5.2: OANDA Integration
- [ ] REST API v20 client
- [ ] OAuth2 authentication
- [ ] Order management
- [ ] Position tracking
- [ ] Streaming prices

### Phase 5.3: Binance Integration
- [ ] WebSocket streams
- [ ] REST API client
- [ ] HMAC authentication
- [ ] Futures support
- [ ] Testnet mode

**Success Criteria:**
- Execute paper trades successfully
- Connect to OANDA practice account
- Stream real-time prices

## 🛡️ Milestone 6: Production Hardening (Week 6)
**Goal:** Ready for real money deployment

### Phase 6.1: Risk Management
- [ ] Position limits
- [ ] Daily loss limits
- [ ] Circuit breakers
- [ ] Margin monitoring
- [ ] Kill switch

### Phase 6.2: Security
- [ ] Vault integration for secrets
- [ ] API key rotation
- [ ] Audit logging
- [ ] Rate limiting per user
- [ ] Input sanitization

### Phase 6.3: Reliability
- [ ] Graceful degradation
- [ ] Retry mechanisms
- [ ] Dead letter queues
- [ ] Health monitoring
- [ ] Backup & recovery

### Phase 6.4: Compliance
- [ ] Trade reconciliation
- [ ] Regulatory reporting
- [ ] Data retention policies
- [ ] User agreements

**Success Criteria:**
- 99.9% uptime over 7 days
- Zero security vulnerabilities
- Full audit trail

## 🌍 Milestone 7: Scale & Deploy (Week 7+)
**Goal:** Cloud deployment and scaling

### Phase 7.1: Cloud Infrastructure
- [ ] Kubernetes manifests
- [ ] Helm charts
- [ ] Terraform scripts
- [ ] CI/CD pipelines
- [ ] Blue-green deployment

### Phase 7.2: Performance
- [ ] Database indexing
- [ ] Caching strategy
- [ ] CDN setup
- [ ] Load balancing
- [ ] Horizontal scaling

### Phase 7.3: Multi-tenancy
- [ ] User authentication
- [ ] Team workspaces
- [ ] Resource quotas
- [ ] Billing integration
- [ ] Admin panel

**Success Criteria:**
- Handle 1000+ concurrent users
- Sub-second response times
- Multi-region deployment

## Dependencies & Prerequisites

### Required Before Starting
- Go 1.22+
- Node.js 20+
- Rust 1.75+
- PostgreSQL 15+
- Redis or NATS

### External Services
- LLM API key (Anthropic/OpenAI)
- Market data API key
- Broker demo accounts

## Version History
- v0.1: Foundation (Milestone 1)
- v0.2: LLM Integration (Milestone 2)
- v0.3: Backtest Engine (Milestone 3)
- v0.4: Portfolio System (Milestone 4)
- v0.5: Broker Integration (Milestone 5)
- v0.6: Production Ready (Milestone 6)
- v1.0: Cloud Scale (Milestone 7)