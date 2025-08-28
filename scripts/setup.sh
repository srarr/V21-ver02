#!/bin/bash
# Initial project setup script

echo "🚀 Setting up Heliox ATLAS v21 Project"
echo "======================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track setup status
SETUP_ERRORS=0

# Helper function to check and report status
setup_step() {
    local step_name="$1"
    local command="$2"
    local success_msg="$3"
    local error_msg="$4"
    
    echo -e "${BLUE}📦 $step_name...${NC}"
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $success_msg${NC}"
        return 0
    else
        echo -e "${RED}❌ $error_msg${NC}"
        ((SETUP_ERRORS++))
        return 1
    fi
}

# Check if we're in the right directory
if [ ! -f "ROADMAP.md" ] || [ ! -f "Makefile" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

echo "📂 Current directory: $(pwd)"
echo ""

# 1. Verify system requirements
echo -e "${BLUE}=== System Requirements Check ===${NC}"
./scripts/verify-setup.sh >/dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Some requirements missing. Continuing with setup...${NC}"
}

# 2. Create .env file if it doesn't exist
echo ""
echo -e "${BLUE}=== Environment Configuration ===${NC}"
if [ ! -f .env ]; then
    echo -e "${BLUE}📝 Creating .env file from template...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env from .env.example${NC}"
        echo -e "${YELLOW}⚠️  Please edit .env and set required values${NC}"
    elif [ -f .env.full.example ]; then
        cp .env.full.example .env
        echo -e "${GREEN}✅ Created .env from .env.full.example${NC}"
        echo -e "${YELLOW}⚠️  Please edit .env and set required values${NC}"
    else
        echo -e "${RED}❌ No .env template found${NC}"
        ((SETUP_ERRORS++))
    fi
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# 3. Initialize git repository if not present
echo ""
echo -e "${BLUE}=== Version Control ===${NC}"
if [ ! -d .git ]; then
    setup_step "Initialize Git repository" "git init" "Git repository initialized" "Failed to initialize git repository"
    
    # Create initial .gitignore if it doesn't exist
    if [ ! -f .gitignore ]; then
        echo -e "${BLUE}📝 Creating .gitignore...${NC}"
        cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.*.local

# Dependencies
node_modules/
vendor/

# Build outputs
dist/
build/
.svelte-kit/
target/
tmp/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
.nyc_output/

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Local snapshots (keep in repo but ignore temp)
.snapshots/*.tmp

# Database
*.sqlite
*.db

# Temporary files
.tmp/
temp/
EOF
        echo -e "${GREEN}✅ Created .gitignore${NC}"
    fi
else
    echo -e "${GREEN}✅ Git repository already initialized${NC}"
fi

# 4. Create necessary directories
echo ""
echo -e "${BLUE}=== Directory Structure ===${NC}"

REQUIRED_DIRS=(
    "apps/api"
    "apps/web"
    "apps/orchestrator"
    "tests/integration"
    "tests/unit"
    "logs"
    ".snapshots"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    setup_step "Create $dir directory" "mkdir -p $dir" "$dir directory ready" "Failed to create $dir"
done

# 5. Create placeholder README files in app directories
echo ""
echo -e "${BLUE}=== Application Structure ===${NC}"

if [ ! -f apps/api/README.md ]; then
    cat > apps/api/README.md << 'EOF'
# Heliox API Gateway

Go/Gin API server for Heliox trading platform.

## Development

```bash
# Install dependencies
go mod tidy

# Run development server
go run cmd/api/main.go

# Run tests
go test ./...
```

## Structure

- `cmd/api/` - Application entry point
- `internal/handlers/` - HTTP handlers
- `internal/middleware/` - HTTP middleware
- `internal/services/` - Business logic
- `internal/models/` - Data models
EOF
    echo -e "${GREEN}✅ Created apps/api/README.md${NC}"
fi

if [ ! -f apps/web/README.md ]; then
    cat > apps/web/README.md << 'EOF'
# Heliox Frontend

SvelteKit frontend for Heliox trading platform.

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

## Features

- Chat interface for strategy creation
- Real-time event streaming (SSE)
- Timeline visualization
- Metrics dashboard
- Portfolio management
EOF
    echo -e "${GREEN}✅ Created apps/web/README.md${NC}"
fi

if [ ! -f apps/orchestrator/README.md ]; then
    cat > apps/orchestrator/README.md << 'EOF'
# Heliox Orchestrator

LangGraph orchestration engine for strategy generation.

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test
```

## Nodes

- **Architect** - Convert prompt to blueprint
- **Synth** - CEGIS synthesis
- **T0/T1/T2/T3** - Backtest phases
- **Pack** - Create HSP package
EOF
    echo -e "${GREEN}✅ Created apps/orchestrator/README.md${NC}"
fi

# 6. Initialize package files for Node.js apps
echo ""
echo -e "${BLUE}=== Package Configuration ===${NC}"

if [ ! -f apps/web/package.json ] && command -v node >/dev/null 2>&1; then
    echo -e "${BLUE}📦 Creating web app package.json...${NC}"
    cat > apps/web/package.json << 'EOF'
{
  "name": "heliox-web",
  "version": "0.1.0",
  "type": "module",
  "private": true,
  "scripts": {
    "dev": "vite dev",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "type-check": "svelte-check --tsconfig ./tsconfig.json"
  },
  "devDependencies": {
    "@sveltejs/adapter-auto": "^2.0.0",
    "@sveltejs/kit": "^2.0.0",
    "@sveltejs/vite-plugin-svelte": "^3.0.0",
    "svelte": "^4.2.7",
    "svelte-check": "^3.6.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.3",
    "vitest": "^1.0.0"
  },
  "dependencies": {
    "zod": "^3.22.4"
  }
}
EOF
    echo -e "${GREEN}✅ Created web package.json${NC}"
fi

if [ ! -f apps/orchestrator/package.json ] && command -v node >/dev/null 2>&1; then
    echo -e "${BLUE}📦 Creating orchestrator package.json...${NC}"
    cat > apps/orchestrator/package.json << 'EOF'
{
  "name": "heliox-orchestrator",
  "version": "0.1.0",
  "type": "module",
  "private": true,
  "scripts": {
    "dev": "tsx src/index.ts",
    "build": "tsc",
    "test": "vitest",
    "type-check": "tsc --noEmit"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0",
    "vitest": "^1.0.0"
  },
  "dependencies": {
    "@langchain/core": "^0.1.0",
    "zod": "^3.22.4"
  }
}
EOF
    echo -e "${GREEN}✅ Created orchestrator package.json${NC}"
fi

# 7. Initialize Go module for API if Go is available
if [ ! -f apps/api/go.mod ] && command -v go >/dev/null 2>&1; then
    echo -e "${BLUE}📦 Initializing Go module for API...${NC}"
    cd apps/api
    go mod init heliox-api >/dev/null 2>&1 && echo -e "${GREEN}✅ Go module initialized${NC}" || echo -e "${RED}❌ Failed to initialize Go module${NC}"
    cd ../..
fi

# 8. Make all scripts executable
echo ""
echo -e "${BLUE}=== Script Permissions ===${NC}"
setup_step "Make scripts executable" "chmod +x scripts/*.sh .claude/*.sh" "Scripts are executable" "Failed to set script permissions"

# 9. Database setup check
echo ""
echo -e "${BLUE}=== Database Setup ===${NC}"
if [ -f .env ]; then
    source .env
    if [ -n "$POSTGRES_DSN" ]; then
        if psql "$POSTGRES_DSN" -c 'SELECT 1' >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Database connection successful${NC}"
            
            # Check if schema is applied
            if psql "$POSTGRES_DSN" -c "SELECT * FROM projects LIMIT 1" >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Database schema already applied${NC}"
            else
                echo -e "${BLUE}📊 Applying database schema...${NC}"
                if [ -f contracts/schemas/sql/migrations/001_init.sql ]; then
                    psql "$POSTGRES_DSN" < contracts/schemas/sql/migrations/001_init.sql >/dev/null 2>&1 && \
                        echo -e "${GREEN}✅ Database schema applied${NC}" || \
                        echo -e "${RED}❌ Failed to apply schema${NC}"
                else
                    echo -e "${YELLOW}⚠️  Schema file not found${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Database not accessible (will work in development mode)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  POSTGRES_DSN not configured${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Environment not configured${NC}"
fi

# 10. Create initial snapshot
echo ""
echo -e "${BLUE}=== Initial Snapshot ===${NC}"
if [ ! -f .snapshots/initial-setup.tar.gz ]; then
    setup_step "Create initial snapshot" "./scripts/create-snapshot.sh 'Initial setup complete' >/dev/null" "Initial snapshot created" "Failed to create snapshot"
else
    echo -e "${GREEN}✅ Initial snapshot already exists${NC}"
fi

# 11. Update context
echo ""
echo -e "${BLUE}=== Context Update ===${NC}"
if [ -f .claude/context.json ]; then
    jq '.setupCompleted = true | .lastSetup = now | todate' .claude/context.json > tmp.json && mv tmp.json .claude/context.json
    echo -e "${GREEN}✅ Context updated with setup completion${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}=== Setup Summary ===${NC}"
if [ $SETUP_ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo ""
    echo "✅ All components ready for development"
    echo "✅ Environment configured"
    echo "✅ Directory structure created"
    echo "✅ Scripts and permissions set"
    echo "✅ Initial snapshot created"
    echo ""
    echo -e "${BLUE}🎯 Next Steps:${NC}"
    echo "1. Review and update .env with your API keys"
    echo "2. Run 'make verify' to check your setup"
    echo "3. Run 'make help' to see available commands" 
    echo "4. Check HANDOFF.md for current development status"
    echo "5. Start development with your first phase"
    echo ""
    echo -e "${BLUE}📚 Useful Commands:${NC}"
    echo "  make verify         # Verify environment"
    echo "  make health-check   # Check system health" 
    echo "  make dev            # Start all services"
    echo "  make snapshot       # Create backup"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  Setup completed with $SETUP_ERRORS issues${NC}"
    echo ""
    echo "Please address the issues above and run setup again."
    echo "You can also continue with development and fix issues as needed."
    echo ""
    echo "Run 'make verify' to check what still needs attention."
    exit 1
fi