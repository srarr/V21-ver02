# Makefile - Heliox ATLAS v21 Project Automation
.PHONY: help dev test clean setup verify rollback db-up db-down seed reset

# Default target
help:
	@echo "Heliox ATLAS v21 - Available commands:"
	@echo "  make setup          - Initial project setup"
	@echo "  make dev            - Start all dev services"
	@echo "  make dev-api        - Start API server only"
	@echo "  make dev-web        - Start frontend only"
	@echo "  make dev-orchestrator - Start orchestrator only"
	@echo "  make db-up          - Start Supabase (database)"
	@echo "  make db-down        - Stop Supabase"
	@echo "  make seed           - Seed database with test data"
	@echo "  make reset          - Reset database (migrations + seed)"
	@echo "  make test           - Run all tests"
	@echo "  make test-unit      - Run unit tests"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test-contracts - Test API contracts with Schemathesis"
	@echo "  make db-migrate     - Apply database migrations"
	@echo "  make db-reset       - Reset database"
	@echo "  make db-seed        - Seed test data"
	@echo "  make verify         - Verify setup and health"
	@echo "  make snapshot       - Create state snapshot"
	@echo "  make rollback       - Rollback to previous state"
	@echo "  make docker-up      - Start Docker services"
	@echo "  make docker-down    - Stop Docker services"
	@echo "  make clean          - Clean generated files"

# Setup and verification
setup: check-deps
	@echo "🚀 Setting up Heliox project..."
	@./scripts/setup.sh
	@./scripts/verify-setup.sh

check-deps:
	@echo "📦 Checking dependencies..."
	@command -v go >/dev/null 2>&1 || { echo "❌ Go not installed - visit https://go.dev"; exit 1; }
	@command -v node >/dev/null 2>&1 || { echo "❌ Node.js not installed - visit https://nodejs.org"; exit 1; }
	@command -v psql >/dev/null 2>&1 || { echo "❌ PostgreSQL client not installed"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "❌ jq not installed - needed for JSON processing"; exit 1; }
	@echo "✅ All required dependencies found"

verify:
	@echo "✅ Verifying setup..."
	@./scripts/verify-setup.sh
	@./scripts/health-check.sh

# Development services
dev: check-deps
	@echo "🔧 Starting all services..."
	@make -j3 dev-api dev-web dev-orchestrator

dev-api:
	@echo "🟢 Starting API Gateway..."
	@if [ -d "apps/api" ]; then \
		cd apps/api && go run cmd/api/main.go; \
	else \
		echo "⚠️  API not implemented yet - run Phase 1.2"; \
	fi

dev-web:
	@echo "🟢 Starting Frontend..."
	@if [ -d "apps/web" ]; then \
		cd apps/web && npm run dev; \
	else \
		echo "⚠️  Frontend not implemented yet - run Phase 1.4"; \
	fi

dev-orchestrator:
	@echo "🟢 Starting Orchestrator..."
	@if [ -d "apps/orchestrator" ]; then \
		cd apps/orchestrator && npm run dev; \
	else \
		echo "⚠️  Orchestrator not implemented yet - run Phase 1.3"; \
	fi

# Database operations
db-up:
	@echo "🐘 Starting Supabase..."
	@command -v supabase >/dev/null 2>&1 && supabase start || echo "⚠️  Supabase CLI not found. Install with: npm i -g supabase"

db-down:
	@echo "🧹 Stopping Supabase..."
	@command -v supabase >/dev/null 2>&1 && supabase stop || true

db-migrate:
	@echo "📊 Applying migrations..."
	@./scripts/db-migrate.sh

db-reset:
	@echo "🔄 Resetting database..."
	@./scripts/db-reset.sh
	@make db-migrate
	@make db-seed

db-seed:
	@echo "🌱 Seeding database..."
	@./scripts/db-seed.sh

seed: db-seed
	@echo "✅ Database seeded"

reset:
	@echo "♻️  Resetting database with migrations and seed..."
	@command -v supabase >/dev/null 2>&1 && supabase db reset || echo "⚠️  Supabase CLI not found"

# Testing
test: test-unit test-integration test-contracts

test-unit:
	@echo "🧪 Running unit tests..."
	@if [ -d "apps/api" ]; then cd apps/api && go test ./...; fi
	@if [ -d "apps/web" ]; then cd apps/web && npm test; fi
	@if [ -d "apps/orchestrator" ]; then cd apps/orchestrator && npm test; fi

test-integration:
	@echo "🔗 Running integration tests..."
	@if [ -d "tests/integration" ]; then \
		cd tests/integration && npm test; \
	else \
		echo "⚠️  Integration tests not setup yet"; \
	fi

test-contracts:
	@echo "📜 Testing API contracts..."
	@if command -v schemathesis >/dev/null 2>&1; then \
		schemathesis run contracts/openapi.yaml --base-url=http://localhost:8080; \
	else \
		echo "⚠️  Schemathesis not installed - pip install schemathesis"; \
	fi

# State management and rollback
snapshot:
	@echo "📸 Creating state snapshot..."
	@./scripts/create-snapshot.sh

rollback:
	@echo "⏮️  Rolling back to previous state..."
	@./scripts/rollback.sh

save-context:
	@echo "💾 Saving Claude context..."
	@./.claude/save-context.sh

load-context:
	@echo "📂 Loading Claude context..."
	@./.claude/load-context.sh

# Docker operations (for later phases)
docker-build:
	@echo "🐳 Building Docker images..."
	@if [ -f "docker-compose.yml" ]; then \
		docker-compose build; \
	else \
		echo "⚠️  Docker compose not setup yet - Phase 5+"; \
	fi

docker-up:
	@echo "🐳 Starting Docker services..."
	@if [ -f "docker-compose.yml" ]; then \
		docker-compose up -d; \
	else \
		echo "⚠️  Docker compose not setup yet - Phase 5+"; \
	fi

docker-down:
	@echo "🐳 Stopping Docker services..."
	@if [ -f "docker-compose.yml" ]; then \
		docker-compose down; \
	else \
		echo "⚠️  Docker compose not setup yet"; \
	fi

docker-logs:
	@if [ -f "docker-compose.yml" ]; then \
		docker-compose logs -f; \
	else \
		echo "⚠️  Docker compose not setup yet"; \
	fi

# Git helpers
git-snapshot:
	@echo "📝 Creating git snapshot..."
	@git add -A
	@git commit -m "snapshot: $(shell date +%Y%m%d-%H%M%S)" || true
	@git tag snapshot-$(shell date +%Y%m%d-%H%M%S)

# Maintenance
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -rf apps/api/tmp 2>/dev/null || true
	@rm -rf apps/web/.svelte-kit 2>/dev/null || true
	@rm -rf apps/web/build 2>/dev/null || true
	@rm -rf apps/orchestrator/dist 2>/dev/null || true
	@rm -rf coverage 2>/dev/null || true
	@rm -rf .nyc_output 2>/dev/null || true
	@rm -rf node_modules/.cache 2>/dev/null || true
	@echo "✅ Cleanup complete"

# Validation
validate-contracts:
	@echo "📋 Validating OpenAPI contracts..."
	@if command -v swagger-codegen >/dev/null 2>&1; then \
		swagger-codegen validate -i contracts/openapi.yaml; \
	else \
		echo "⚠️  swagger-codegen not installed"; \
	fi

# Install tools (helper targets)
install-tools:
	@echo "🔧 Installing development tools..."
	@echo "Installing Go tools..."
	@go install github.com/cosmtrek/air@latest || true
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest || true
	@echo "Installing Node.js tools..."
	@npm install -g typescript tsx @sveltejs/kit || true
	@echo "Installing Python tools..."
	@pip install schemathesis || true
	@echo "✅ Tools installation complete"

# Help for specific phases
help-phase-1:
	@echo "Phase 1 Commands:"
	@echo "  make setup           - Setup environment"
	@echo "  make db-migrate      - Setup database"
	@echo "  make dev-api         - Start API development"

help-phase-2:
	@echo "Phase 2 Commands:"
	@echo "  make test-contracts  - Test API contracts"
	@echo "  make dev-orchestrator - Start orchestrator"

help-phase-3:
	@echo "Phase 3 Commands:"
	@echo "  make dev-web         - Start frontend"
	@echo "  make test-integration - Full integration tests"

# === CHECKPOINT MANAGEMENT ===

checkpoint: ## Run checkpoint manager agent
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "📋 CHECKPOINT MANAGER"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Run in Claude Code:"
	@echo "  /agents checkpoint-manager \"verify and fix\""
	@echo ""

checkpoint-auto: ## Auto-detect and suggest checkpoint update
	@bash scripts/auto-checkpoint-trigger.sh auto

task-done: ## Mark task as done and trigger checkpoint
	@bash scripts/auto-checkpoint-trigger.sh task-done "$(TASK)"
	@echo ""
	@echo "Task marked as complete. Checkpoint update required."

phase-done: ## Mark phase as done and trigger checkpoint  
	@bash scripts/auto-checkpoint-trigger.sh phase-done "$(PHASE)"
	@echo ""
	@echo "Phase marked as complete. Checkpoint update required."

session-start: ## Run at session start for checkpoint verification
	@bash scripts/auto-checkpoint-trigger.sh session-start

# Wrapper targets that include checkpoint
test-with-checkpoint: test ## Run tests then update checkpoint
	@$(MAKE) checkpoint-auto

build-with-checkpoint: dev-api ## Build then update checkpoint
	@$(MAKE) checkpoint-auto

commit-with-checkpoint: ## Commit changes with checkpoint reminder
	@git add -A
	@git commit || true
	@$(MAKE) checkpoint-auto