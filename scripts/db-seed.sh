#!/bin/bash
# Seed database with test data

echo "🌱 Seeding database with test data..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if .env exists and source it
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Create .env from .env.example and configure POSTGRES_DSN"
    exit 1
fi

source .env

# Check if POSTGRES_DSN is set
if [ -z "$POSTGRES_DSN" ]; then
    echo -e "${RED}❌ POSTGRES_DSN not set in .env${NC}"
    echo "Configure your PostgreSQL connection string in .env"
    exit 1
fi

# Test database connection
echo -e "${BLUE}🔌 Testing database connection...${NC}"
if ! psql "$POSTGRES_DSN" -c 'SELECT 1' >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to database${NC}"
    echo "Connection string: $POSTGRES_DSN"
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}"

# Check if tables exist
echo -e "${BLUE}🔍 Checking database schema...${NC}"
TABLES_EXIST=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('projects', 'docs', 'tasks');" 2>/dev/null | tr -d ' ')

if [ "${TABLES_EXIST:-0}" -lt 3 ]; then
    echo -e "${RED}❌ Required tables not found${NC}"
    echo "Run 'make db-migrate' first to create the schema"
    exit 1
fi

echo -e "${GREEN}✅ Required tables found${NC}"

# Check if data already exists
EXISTING_PROJECTS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM projects;" 2>/dev/null | tr -d ' ')
EXISTING_DOCS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM docs;" 2>/dev/null | tr -d ' ')
EXISTING_TASKS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM tasks;" 2>/dev/null | tr -d ' ')

echo ""
echo -e "${BLUE}📊 Current data counts:${NC}"
echo "  Projects: ${EXISTING_PROJECTS:-0}"
echo "  Documents: ${EXISTING_DOCS:-0}"
echo "  Tasks: ${EXISTING_TASKS:-0}"

if [ "${EXISTING_PROJECTS:-0}" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Database already contains data${NC}"
    read -p "Continue with seeding? This may create duplicates (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Seeding cancelled${NC}"
        exit 0
    fi
fi

echo ""
echo -e "${BLUE}🌱 Starting database seeding...${NC}"

# Create seed data SQL
SEED_SQL="
-- Insert sample project (if not exists)
INSERT INTO projects (id, name, description, created_at)
VALUES (
    gen_random_uuid(),
    'V21 Local Project', 
    'Local-first Claude Code accelerator with trading platform',
    NOW()
) ON CONFLICT (name) DO NOTHING;

-- Get the project ID for reference
DO \$\$
DECLARE
    project_uuid UUID;
BEGIN
    SELECT id INTO project_uuid FROM projects WHERE name = 'V21 Local Project';
    
    -- Insert framework documents
    INSERT INTO docs (id, project_id, type, content, updated_at) VALUES
    (gen_random_uuid(), project_uuid, 'PRD', '# PRD - V21 Claude Code Accelerator
This project creates a trading strategy platform using AI-driven strategy generation.
Goals: Local-first development, contract-first API design, Sub-Agent orchestration.', NOW()),
    
    (gen_random_uuid(), project_uuid, 'PLANNING', '# PLANNING - Architecture & Implementation
Tech Stack: SvelteKit + Go/Gin + LangGraph + Rust + PostgreSQL + NATS
Deployment: Local development with Docker production deployment.', NOW()),
    
    (gen_random_uuid(), project_uuid, 'CLAUDE', '# CLAUDE - Operating Guide
Framework for Claude Code to maintain continuity and context.
Includes Sub-Agent patterns and memory persistence.', NOW()),
    
    (gen_random_uuid(), project_uuid, 'TASKS', '# TASKS - Development Milestones
Phase 1: Foundation with Mocks
Phase 2: Real LLM Integration  
Phase 3: Backtest Engine
Phase 4: Portfolio Management
Phase 5: Broker Integration', NOW())
    
    ON CONFLICT DO NOTHING;
    
    -- Insert sample tasks for different phases
    INSERT INTO tasks (id, project_id, title, body, phase, status, dod, created_at, updated_at) VALUES
    
    -- Phase 1 tasks
    (gen_random_uuid(), project_uuid, 'Setup Infrastructure', 
     'Create project structure, database schema, and OpenAPI contracts', 
     1, 'DONE', ''{}''::jsonb, NOW(), NOW()),
     
    (gen_random_uuid(), project_uuid, 'Implement API Gateway', 
     'Create Go/Gin API server with health check, CORS, and basic endpoints', 
     1, 'TODO', ''{"endpoints": ["/health", "/v1/runs", "/v1/portfolio"], "middleware": ["CORS", "logging"]}''::jsonb, NOW(), NOW()),
     
    (gen_random_uuid(), project_uuid, 'Create LangGraph Orchestrator', 
     'Implement state machine with mock nodes for strategy generation', 
     1, 'TODO', ''{"nodes": ["Architect", "Synth", "T0", "Pack"], "events": "NATS publishing"}''::jsonb, NOW(), NOW()),
     
    (gen_random_uuid(), project_uuid, 'Build SvelteKit Frontend', 
     'Chat interface with SSE streaming and timeline visualization', 
     1, 'TODO', ''{"components": ["ChatInput", "Timeline", "Metrics"], "streaming": "SSE"}''::jsonb, NOW(), NOW()),
     
    -- Phase 2 tasks  
    (gen_random_uuid(), project_uuid, 'Integrate LLM Services', 
     'Connect Anthropic Claude and OpenAI GPT-4 with prompt templates', 
     2, 'TODO', ''{"providers": ["Anthropic", "OpenAI", "Ollama"], "templates": "strategy generation"}''::jsonb, NOW(), NOW()),
     
    (gen_random_uuid(), project_uuid, 'Create Strategy DSL', 
     'Define domain-specific language for trading strategies', 
     2, 'TODO', ''{"parser": "DSL to executable", "validation": "syntax rules"}''::jsonb, NOW(), NOW()),
     
    -- Phase 3 tasks
    (gen_random_uuid(), project_uuid, 'Build Rust Backtest Engine', 
     'High-performance backtesting with historical market data', 
     3, 'TODO', ''{"performance": "sub-second", "data": "Yahoo Finance", "metrics": "Sharpe, drawdown"}''::jsonb, NOW(), NOW()),
     
    (gen_random_uuid(), project_uuid, 'Implement Risk Metrics', 
     'Calculate Sharpe ratio, max drawdown, Monte Carlo simulation', 
     3, 'TODO', ''{"metrics": ["sharpe", "drawdown", "win_rate"], "simulation": "Monte Carlo"}''::jsonb, NOW(), NOW());
     
    -- Insert sample scenario data for testing
    INSERT INTO projects (id, name, description, created_at) VALUES
    (gen_random_uuid(), 'Demo Trading Strategies', 'Sample strategies for testing and demonstration', NOW()),
    (gen_random_uuid(), 'Backtest Scenarios', 'Historical backtesting scenarios for validation', NOW())
    ON CONFLICT (name) DO NOTHING;
    
END \$\$;

-- Insert sample sub-agents configuration
INSERT INTO projects (id, name, description, created_at)
SELECT gen_random_uuid(), 'Sub-Agents Registry', 'Configuration for Claude Code sub-agents', NOW()
WHERE NOT EXISTS (SELECT 1 FROM projects WHERE name = 'Sub-Agents Registry');

DO \$\$
DECLARE
    registry_uuid UUID;
BEGIN
    SELECT id INTO registry_uuid FROM projects WHERE name = 'Sub-Agents Registry';
    
    INSERT INTO subagents (id, project_id, name, role, prompt) VALUES
    (gen_random_uuid(), registry_uuid, 'PRD Keeper', 'Validation', 
     'Ensure all changes align with PRD requirements and V21.ini specifications'),
    (gen_random_uuid(), registry_uuid, 'Contract Scribe', 'API Design', 
     'Create and maintain OpenAPI specifications and database schemas'),
    (gen_random_uuid(), registry_uuid, 'DB Cartographer', 'Data Modeling', 
     'Design normalized database schemas with proper migrations'),
    (gen_random_uuid(), registry_uuid, 'Task Runner', 'Implementation', 
     'Implement features according to contracts and DoD requirements'),
    (gen_random_uuid(), registry_uuid, 'Verifier', 'Quality Assurance', 
     'Run tests, verify functionality, and ensure quality standards')
    ON CONFLICT DO NOTHING;
END \$\$;
"

# Execute seed SQL
echo -e "${BLUE}📝 Inserting seed data...${NC}"
if psql "$POSTGRES_DSN" -c "$SEED_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Seed data inserted successfully${NC}"
else
    echo -e "${RED}❌ Failed to insert seed data${NC}"
    echo "Check PostgreSQL logs for detailed error information"
    exit 1
fi

# Verify seed data
echo ""
echo -e "${BLUE}🔍 Verifying seed data...${NC}"
NEW_PROJECTS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM projects;" 2>/dev/null | tr -d ' ')
NEW_DOCS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM docs;" 2>/dev/null | tr -d ' ')
NEW_TASKS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM tasks;" 2>/dev/null | tr -d ' ')
NEW_SUBAGENTS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM subagents;" 2>/dev/null | tr -d ' ')

echo ""
echo -e "${BLUE}📊 Final data counts:${NC}"
echo "  Projects: ${NEW_PROJECTS:-0}"
echo "  Documents: ${NEW_DOCS:-0}" 
echo "  Tasks: ${NEW_TASKS:-0}"
echo "  Sub-agents: ${NEW_SUBAGENTS:-0}"

# Show sample data
echo ""
echo -e "${BLUE}📋 Sample Projects:${NC}"
psql "$POSTGRES_DSN" -c "SELECT name, description FROM projects ORDER BY created_at;" 2>/dev/null | head -10

echo ""
echo -e "${BLUE}📋 Sample Tasks by Phase:${NC}"
psql "$POSTGRES_DSN" -c "SELECT phase, status, title FROM tasks ORDER BY phase, created_at LIMIT 10;" 2>/dev/null

# Update context if available
if [ -f .claude/context.json ]; then
    jq --arg projects "$NEW_PROJECTS" --arg docs "$NEW_DOCS" --arg tasks "$NEW_TASKS" \
        '.lastSeed = {projects: ($projects | tonumber), docs: ($docs | tonumber), tasks: ($tasks | tonumber), timestamp: now | todate}' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

echo ""
echo -e "${GREEN}🎉 Database seeding completed successfully!${NC}"
echo ""
echo "✅ Sample projects created"
echo "✅ Framework documents loaded" 
echo "✅ Development tasks defined"
echo "✅ Sub-agents configured"
echo ""
echo "Next steps:"
echo "  1. Run 'make health-check' to verify setup"
echo "  2. Start development with 'make dev'"
echo "  3. Check tasks with: psql \$POSTGRES_DSN -c 'SELECT * FROM tasks ORDER BY phase;'"