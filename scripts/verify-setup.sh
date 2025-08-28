#!/bin/bash
# Verify development environment setup

set -e

echo "🔍 Verifying Heliox setup..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check function
check() {
    if eval "$2" >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} $1"
        return 0
    else
        echo -e "${RED}❌${NC} $1 - $3"
        return 1
    fi
}

# Track failures
FAILURES=0

echo "=== System Requirements ==="
check "Go 1.22+" "go version | grep -E 'go1\.(2[2-9]|[3-9][0-9])'" "Install from https://go.dev" || ((FAILURES++))
check "Node.js 20+" "node -v | grep -E 'v(2[0-9]|[3-9][0-9])'" "Install from https://nodejs.org" || ((FAILURES++))
check "PostgreSQL client" "which psql" "Install PostgreSQL client" || ((FAILURES++))
check "jq (JSON processor)" "which jq" "Install jq for JSON processing" || ((FAILURES++))
check "curl" "which curl" "Install curl for API testing" || ((FAILURES++))
check "git" "which git" "Install git for version control" || ((FAILURES++))

echo ""
echo "=== Optional Tools ==="
check "Redis client" "which redis-cli" "Install Redis for caching (optional)" || true
check "Docker" "which docker" "Install Docker for containerization (Phase 5+)" || true
check "Rust" "which rustc" "Install Rust for backtest engine (Phase 3+)" || true
check "Python/pip" "which pip" "Install Python for schemathesis (optional)" || true

echo ""
echo "=== Project Structure ==="
check "Apps directory" "test -d apps" "Run from project root directory" || ((FAILURES++))
check "Contracts directory" "test -d contracts" "Contracts directory missing" || ((FAILURES++))
check "OpenAPI spec" "test -f contracts/openapi.yaml" "OpenAPI specification missing" || ((FAILURES++))
check "Database schema" "test -f contracts/schemas/sql/migrations/001_init.sql" "Database schema missing" || ((FAILURES++))
check "Framework files" "test -f ROADMAP.md && test -f CONTINUITY.md && test -f DECISIONS.md && test -f HANDOFF.md" "Framework documentation missing" || ((FAILURES++))
check "Makefile" "test -f Makefile" "Makefile missing - run make commands won't work" || ((FAILURES++))
check "Environment template" "test -f .env.example" "Environment template missing" || ((FAILURES++))

echo ""
echo "=== Environment Configuration ==="
if [ -f .env ]; then
    check "Environment file exists" "test -f .env" "Environment file found"
    
    # Source .env and check critical variables
    set -a
    source .env
    set +a
    
    check "BACKEND_HTTP_ADDR set" "test -n '$BACKEND_HTTP_ADDR'" "Set BACKEND_HTTP_ADDR in .env"
    
    if [ -n "$POSTGRES_DSN" ]; then
        check "PostgreSQL connection" "psql '$POSTGRES_DSN' -c 'SELECT 1' >/dev/null 2>&1" "Database not accessible - check connection string and server" || true
    else
        echo -e "${YELLOW}⚠️${NC} POSTGRES_DSN not set in .env"
    fi
else
    echo -e "${YELLOW}⚠️${NC} .env file not found - copy .env.example to .env and configure"
    ((FAILURES++))
fi

echo ""
echo "=== Service Status ==="
check "API Gateway" "curl -f '$BACKEND_HTTP_ADDR/health' >/dev/null 2>&1" "API not running (will start with make dev-api)" || true
check "Frontend dev server" "curl -f http://localhost:5173 >/dev/null 2>&1" "Frontend not running (will start with make dev-web)" || true

if command -v redis-cli >/dev/null 2>&1; then
    check "Redis" "redis-cli ping >/dev/null 2>&1" "Redis not running (optional)" || true
fi

if command -v docker >/dev/null 2>&1; then
    check "Docker daemon" "docker ps >/dev/null 2>&1" "Docker daemon not running (optional for now)" || true
fi

# Check for NATS if available
if command -v nats >/dev/null 2>&1; then
    check "NATS server" "nats server ping >/dev/null 2>&1" "NATS not running (will install in Phase 1.3)" || true
fi

echo ""
echo "=== Git Repository ==="
if [ -d .git ]; then
    check "Git repository initialized" "test -d .git" "Git repository found"
    check "Git user configured" "git config user.name >/dev/null 2>&1" "Configure git user: git config user.name 'Your Name'" || true
    check "Git email configured" "git config user.email >/dev/null 2>&1" "Configure git email: git config user.email 'your@email.com'" || true
else
    echo -e "${YELLOW}⚠️${NC} Git repository not initialized (optional but recommended)"
    echo "    Run: git init"
fi

echo ""
echo "=== Development Tools Status ==="
PHASE=$(jq -r '.currentPhase' .claude/context.json 2>/dev/null || echo "unknown")
echo "Current Phase: $PHASE"

case $PHASE in
    "Framework Setup")
        echo "✅ Ready for framework completion"
        echo "Next: Complete scripts and contracts, then run make setup"
        ;;
    "1.1"|"1.2")
        echo "✅ Ready for API development"  
        echo "Next: Create apps/api structure"
        ;;
    "1.3")
        echo "✅ Ready for orchestrator development"
        echo "Next: Install NATS and create apps/orchestrator"
        ;;
    "1.4")
        echo "✅ Ready for frontend development"
        echo "Next: Create apps/web with SvelteKit"
        ;;
    *)
        echo "ℹ️  Check HANDOFF.md for current development status"
        ;;
esac

echo ""
echo "=== Summary ==="
if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo "You're ready to continue development."
    echo ""
    echo "Next steps:"
    echo "  1. Run 'make help' to see available commands"
    echo "  2. Check HANDOFF.md for current status"  
    echo "  3. Continue with current phase development"
    exit 0
else
    echo -e "${RED}❌ $FAILURES critical checks failed${NC}"
    echo ""
    echo "Fix the issues above, then run this script again."
    echo "Common fixes:"
    echo "  - Install missing tools (go, node, postgresql, jq)"
    echo "  - Create .env from .env.example"
    echo "  - Ensure you're in the project root directory"
    echo "  - Run 'make setup' after fixing requirements"
    exit 1
fi