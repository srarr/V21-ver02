#!/bin/bash
# Comprehensive health check for all services

echo "🏥 Heliox Health Check"
echo "========================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Track status
HEALTHY=0
UNHEALTHY=0
WARNING=0

# Health check function
check_health() {
    local service=$1
    local description=$2
    local required=${3:-false}
    
    if ./scripts/check-service.sh "$service" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $description${NC}"
        ((HEALTHY++))
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $description${NC}"
            ((UNHEALTHY++))
        else
            echo -e "${YELLOW}⚠️  $description${NC}"
            ((WARNING++))
        fi
    fi
}

echo ""
echo -e "${BLUE}Core Services${NC}"
echo "-------------"
check_health "postgres" "PostgreSQL Database" true
check_health "api" "API Gateway (Go/Gin)"
check_health "orchestrator" "Orchestrator (LangGraph)"
check_health "frontend" "Frontend (SvelteKit)"

echo ""
echo -e "${BLUE}Supporting Services${NC}"
echo "-------------------"
check_health "redis" "Redis Cache"
check_health "nats" "NATS Message Queue" 
check_health "minio" "MinIO Object Storage"

echo ""
echo -e "${BLUE}Development Tools${NC}"
echo "-----------------"
check_health "docker" "Docker Daemon"

# Check file system health
echo ""
echo -e "${BLUE}File System${NC}"
echo "-----------"

# Check disk space
DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo -e "${RED}❌ Disk space: ${DISK_USAGE}% used${NC}"
    ((UNHEALTHY++))
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  Disk space: ${DISK_USAGE}% used${NC}"
    ((WARNING++))
else
    echo -e "${GREEN}✅ Disk space: ${DISK_USAGE}% used${NC}"
    ((HEALTHY++))
fi

# Check log directory size
if [ -d "logs" ]; then
    LOG_SIZE=$(du -sh logs 2>/dev/null | cut -f1)
    echo -e "${GREEN}✅ Log directory: ${LOG_SIZE}${NC}"
    ((HEALTHY++))
else
    echo -e "${YELLOW}⚠️  Log directory not created yet${NC}"
    ((WARNING++))
fi

# Application Health
echo ""
echo -e "${BLUE}Application Health${NC}"
echo "------------------"

# Check if .env exists and has required variables
if [ -f .env ]; then
    echo -e "${GREEN}✅ Environment file exists${NC}"
    ((HEALTHY++))
    
    # Check key environment variables
    source .env
    
    if [ -n "$BACKEND_HTTP_ADDR" ]; then
        echo -e "${GREEN}✅ Backend address configured${NC}"
        ((HEALTHY++))
    else
        echo -e "${RED}❌ BACKEND_HTTP_ADDR not set${NC}"
        ((UNHEALTHY++))
    fi
    
    if [ -n "$POSTGRES_DSN" ]; then
        echo -e "${GREEN}✅ Database connection configured${NC}"
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠️  POSTGRES_DSN not set${NC}"
        ((WARNING++))
    fi
else
    echo -e "${RED}❌ Environment file missing${NC}"
    echo "   Create .env from .env.example"
    ((UNHEALTHY++))
fi

# Check database schema
if [ -f .env ] && [ -n "$POSTGRES_DSN" ]; then
    if psql "$POSTGRES_DSN" -c "SELECT * FROM projects LIMIT 1" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Database schema applied${NC}"
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠️  Database schema not applied${NC}"
        echo "   Run: make db-migrate"
        ((WARNING++))
    fi
fi

# Git repository health
echo ""
echo -e "${BLUE}Version Control${NC}"
echo "---------------"

if [ -d .git ]; then
    echo -e "${GREEN}✅ Git repository initialized${NC}"
    ((HEALTHY++))
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        CHANGES=$(git status --porcelain | wc -l)
        echo -e "${YELLOW}⚠️  ${CHANGES} uncommitted changes${NC}"
        ((WARNING++))
    else
        echo -e "${GREEN}✅ Working directory clean${NC}"
        ((HEALTHY++))
    fi
    
    # Check for untracked files
    UNTRACKED=$(git status --porcelain | grep '^??' | wc -l)
    if [ "$UNTRACKED" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  ${UNTRACKED} untracked files${NC}"
        ((WARNING++))
    fi
else
    echo -e "${YELLOW}⚠️  Git repository not initialized${NC}"
    echo "   Run: git init"
    ((WARNING++))
fi

# Context and state health
echo ""
echo -e "${BLUE}Framework State${NC}"
echo "---------------"

if [ -f .claude/context.json ]; then
    LAST_UPDATE=$(jq -r '.lastUpdated' .claude/context.json)
    CURRENT_PHASE=$(jq -r '.currentPhase' .claude/context.json)
    CURRENT_TASK=$(jq -r '.activeTask' .claude/context.json)
    
    echo -e "${GREEN}✅ Context file exists${NC}"
    echo "   Phase: $CURRENT_PHASE"
    echo "   Task: $CURRENT_TASK"
    echo "   Updated: $LAST_UPDATE"
    ((HEALTHY++))
else
    echo -e "${RED}❌ Context file missing${NC}"
    ((UNHEALTHY++))
fi

if [ -f .claude/completed.txt ]; then
    COMPLETED_COUNT=$(grep -c "^\[" .claude/completed.txt 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ ${COMPLETED_COUNT} tasks completed${NC}"
    ((HEALTHY++))
fi

# Summary
echo ""
echo -e "${BLUE}Health Summary${NC}"
echo "=============="
echo -e "${GREEN}Healthy: $HEALTHY${NC}"
echo -e "${YELLOW}Warnings: $WARNING${NC}"
echo -e "${RED}Critical: $UNHEALTHY${NC}"

TOTAL=$((HEALTHY + WARNING + UNHEALTHY))
if [ $TOTAL -gt 0 ]; then
    HEALTH_PERCENTAGE=$(( (HEALTHY * 100) / TOTAL ))
    echo "Overall Health: $HEALTH_PERCENTAGE%"
fi

echo ""
if [ $UNHEALTHY -eq 0 ]; then
    if [ $WARNING -eq 0 ]; then
        echo -e "${GREEN}🎉 System is healthy!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  System has warnings but is functional${NC}"
        echo "Address warnings when convenient."
        exit 0
    fi
else
    echo -e "${RED}💥 System has critical issues${NC}"
    echo "Fix critical issues before continuing development."
    echo ""
    echo "Common fixes:"
    echo "  - Start PostgreSQL: systemctl start postgresql (Linux) or brew services start postgresql (Mac)"
    echo "  - Create .env: cp .env.example .env"
    echo "  - Apply migrations: make db-migrate"
    echo "  - Install dependencies: make check-deps"
    exit 1
fi