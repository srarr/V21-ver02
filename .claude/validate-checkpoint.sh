#!/bin/bash

# Checkpoint Validation Script
# Prevents false completion marking by checking actual work evidence

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Checkpoint Validation System ===${NC}"

# Function to validate a phase has actual work done
validate_phase() {
    local phase=$1
    local status=$2
    
    if [ "$status" = "completed" ]; then
        case $phase in
            "1.1")
                # Infrastructure must have migrations and contracts
                if [ ! -f "supabase/migrations/001_init.sql" ]; then
                    echo -e "${RED}✗ Phase 1.1: Missing migration file${NC}"
                    return 1
                fi
                if [ ! -f "contracts/openapi.yaml" ]; then
                    echo -e "${RED}✗ Phase 1.1: Missing OpenAPI contract${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.1: Infrastructure files exist${NC}"
                ;;
                
            "1.2")
                # API must have Go files
                if [ ! -d "apps/api" ] || [ -z "$(find apps/api -name '*.go' 2>/dev/null)" ]; then
                    echo -e "${RED}✗ Phase 1.2: No Go API files found${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.2: Go API files exist${NC}"
                ;;
                
            "1.3")
                # Orchestrator must have TypeScript files
                if [ ! -f "apps/orchestrator/package.json" ]; then
                    echo -e "${RED}✗ Phase 1.3: Missing orchestrator package.json${NC}"
                    return 1
                fi
                if [ ! -f "apps/orchestrator/src/graph.ts" ]; then
                    echo -e "${RED}✗ Phase 1.3: Missing graph.ts${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.3: Orchestrator files exist${NC}"
                ;;
                
            "1.4")
                # Frontend must have SvelteKit project
                if [ ! -f "apps/web/package.json" ]; then
                    echo -e "${RED}✗ Phase 1.4: Missing web package.json${NC}"
                    echo -e "${YELLOW}  Note: Only README.md found - SvelteKit not initialized${NC}"
                    return 1
                fi
                if [ ! -d "apps/web/src/routes" ]; then
                    echo -e "${RED}✗ Phase 1.4: Missing SvelteKit routes${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.4: SvelteKit project exists${NC}"
                ;;
                
            "1.5")
                # Testing must have test files
                if [ ! -d "tests" ] && [ -z "$(find . -name '*.test.ts' -o -name '*.test.js' 2>/dev/null)" ]; then
                    echo -e "${RED}✗ Phase 1.5: No test files found${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.5: Test files exist${NC}"
                ;;
                
            "1.6")
                # UI Safety must have container/presenter structure
                if [ ! -d "apps/web/src/containers" ] && [ ! -d "apps/web/src/components" ]; then
                    echo -e "${RED}✗ Phase 1.6: Missing container/presenter structure${NC}"
                    return 1
                fi
                echo -e "${GREEN}✓ Phase 1.6: UI safety structure exists${NC}"
                ;;
                
            *)
                echo -e "${YELLOW}⚠ Unknown phase: $phase${NC}"
                ;;
        esac
    fi
    return 0
}

# Read todos.json and validate each phase
if [ -f ".claude/todos.json" ]; then
    echo "Validating phase completions..."
    
    # Check each phase
    for phase in "1.1" "1.2" "1.3" "1.4" "1.5" "1.6"; do
        status=$(grep -A2 "\"$phase\":" .claude/todos.json | grep "status" | cut -d'"' -f4)
        if ! validate_phase "$phase" "$status"; then
            echo -e "${RED}ERROR: Phase $phase marked as $status but validation failed!${NC}"
            echo -e "${YELLOW}Recommendation: Set phase $phase to 'pending' in todos.json${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✓ All phase validations passed${NC}"
else
    echo -e "${RED}✗ todos.json not found${NC}"
    exit 1
fi

echo -e "${GREEN}=== Validation Complete ===${NC}"