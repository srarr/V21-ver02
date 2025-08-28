# Architectural Decision Records (ADR)

## Format
Each decision follows this template:
- **Date**: When decided
- **Status**: Proposed | Accepted | Deprecated | Superseded
- **Context**: Why we needed to decide
- **Decision**: What we chose
- **Consequences**: What happens as a result
- **Alternatives Considered**: What else we looked at

---

## ADR-001: Message Queue Selection
**Date**: 2024-01-15  
**Status**: Accepted  
**Context**: Need pub/sub for events between Orchestrator and Gateway  
**Decision**: Use NATS JetStream instead of Redis Streams  
**Consequences**: 
- ✅ Built-in persistence without extra config
- ✅ Better message replay capabilities  
- ✅ Native clustering support
- ❌ One more service to manage
- ❌ Team needs to learn NATS

**Alternatives Considered**:
- Redis Streams: Simpler but less features
- Kafka: Overkill for our scale
- RabbitMQ: More complex setup

---

## ADR-002: Frontend Framework
**Date**: 2024-01-15  
**Status**: Accepted  
**Context**: Need reactive UI with SSE support  
**Decision**: SvelteKit over Next.js  
**Consequences**:
- ✅ Better SSE/WebSocket integration
- ✅ Smaller bundle size
- ✅ Simpler state management
- ❌ Smaller ecosystem than React
- ❌ Less hiring pool

**Alternatives Considered**:
- Next.js: More popular but heavier
- Vue/Nuxt: Good but team unfamiliar
- Plain Vite: Too much setup needed

---

## ADR-003: Database Choice
**Date**: 2024-01-16  
**Status**: Accepted  
**Context**: Need time-series data for backtesting + relational for metadata  
**Decision**: PostgreSQL with TimescaleDB extension  
**Consequences**:
- ✅ Single database for both needs
- ✅ SQL familiarity
- ✅ Good tooling ecosystem
- ❌ Need to tune for time-series
- ❌ Not as fast as specialized TSDBs

**Alternatives Considered**:
- PostgreSQL + InfluxDB: Two databases to manage
- Cassandra: Overkill and complex
- MongoDB: Poor time-series support

---

## ADR-004: API Protocol
**Date**: 2024-01-16  
**Status**: Accepted  
**Context**: Need real-time updates for strategy building progress  
**Decision**: REST + SSE instead of GraphQL or gRPC  
**Consequences**:
- ✅ Simple to implement
- ✅ Wide browser support
- ✅ Easy debugging with curl
- ❌ No type safety across network
- ❌ SSE is one-way only

**Alternatives Considered**:
- GraphQL + Subscriptions: Complex setup
- gRPC-Web: Poor browser support
- WebSockets: Overkill for one-way events

---

## ADR-005: Orchestration Engine
**Date**: 2024-01-17  
**Status**: Accepted  
**Context**: Need state machine for strategy generation workflow  
**Decision**: LangGraph over Temporal or Airflow  
**Consequences**:
- ✅ Native LLM integration
- ✅ Built for AI workflows
- ✅ TypeScript/Python support
- ❌ Less mature than alternatives
- ❌ Smaller community

**Alternatives Considered**:
- Temporal: Overkill for our needs
- Airflow: Too batch-oriented
- Custom state machine: Too much work

---

## ADR-006: LLM Strategy
**Date**: 2024-01-17  
**Status**: Accepted  
**Context**: Need high-quality strategy generation with fallback  
**Decision**: Claude 3 Opus primary, GPT-4 fallback, Ollama for dev  
**Consequences**:
- ✅ Best quality outputs
- ✅ Local dev option
- ✅ Redundancy
- ❌ Multiple API keys needed
- ❌ Cost considerations

**Alternatives Considered**:
- Single provider: Risk of outage
- Only local: Quality issues
- Only cloud: Can't develop offline

---

## ADR-007: Backtest Engine Language
**Date**: 2024-01-18  
**Status**: Accepted  
**Context**: Need high-performance backtesting of strategies  
**Decision**: Rust for engine, exposed via FFI/HTTP  
**Consequences**:
- ✅ Maximum performance
- ✅ Memory safety
- ✅ Good async support
- ❌ Longer development time
- ❌ Fewer developers know Rust

**Alternatives Considered**:
- Go: Slower for number crunching
- C++: Memory safety concerns
- Python/NumPy: Too slow for scale

---

## ADR-008: Storage for Artifacts
**Date**: 2024-01-18  
**Status**: Accepted  
**Context**: Need to store strategy packages, backtest results, reports  
**Decision**: MinIO (S3-compatible) for local, real S3 for production  
**Consequences**:
- ✅ Same API for local/cloud
- ✅ Industry standard
- ✅ Good SDK support
- ❌ Another service locally
- ❌ Learning curve for S3 API

**Alternatives Considered**:
- Local filesystem: Doesn't scale
- PostgreSQL BLOB: Poor for large files
- Custom solution: Reinventing wheel

---

## ADR-009: Authentication Method
**Date**: 2024-01-19  
**Status**: Proposed  
**Context**: Need user auth without complexity  
**Decision**: Supabase Auth with email magic links  
**Consequences**:
- ✅ No password management
- ✅ Built-in email service
- ✅ Row-level security
- ❌ Vendor lock-in
- ❌ Email delivery issues

**Alternatives Considered**:
- Auth0: More expensive
- Custom JWT: Security risks
- OAuth only: Not all users have Google/GitHub

---

## ADR-010: Deployment Strategy
**Date**: 2024-01-19  
**Status**: Proposed  
**Context**: Need to deploy reliably with rollback capability  
**Decision**: Docker + Kubernetes with Helm charts  
**Consequences**:
- ✅ Industry standard
- ✅ Easy rollbacks
- ✅ Horizontal scaling
- ❌ Complexity overhead
- ❌ Need K8s knowledge

**Alternatives Considered**:
- Docker Compose: Doesn't scale
- Serverless: Cold starts hurt UX
- VMs: Too much overhead

---

## Design Principles (Not ADRs but Important)

### Data Flow
- **Unidirectional**: Frontend → Gateway → Orchestrator → Engine → Storage
- **Event-driven**: Components communicate via events, not direct calls
- **Idempotent**: All operations can be retried safely

### Error Handling
- **Fail fast**: Validate early, error immediately
- **Graceful degradation**: Fallback to mock/cache if service down
- **User-friendly**: Technical errors translated to human language

### Security
- **Zero trust**: Validate everything, trust nothing
- **Defense in depth**: Multiple security layers
- **Least privilege**: Minimal permissions everywhere

### Performance
- **Cache aggressively**: But invalidate correctly
- **Async by default**: Never block unless necessary
- **Measure everything**: Can't optimize what you don't measure

---

## Deprecated Decisions

### ~~ADR-000: Monolithic Architecture~~
**Date**: 2024-01-14  
**Status**: Superseded by ADR-001  
**Context**: Started with everything in one service  
**Decision**: Single Node.js app  
**Why Changed**: Couldn't scale, mixed concerns