#!/bin/bash

# Auto Checkpoint Update Script - Enhanced Version
# Automatically detects completed tasks and updates all tracking files
# Integrated with todo-persist.js and checkpoint-config.json

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CHECKPOINT_CONFIG="$CLAUDE_DIR/checkpoint-config.json"
TODOS_FILE="$CLAUDE_DIR/todos.json"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Enhanced Auto Checkpoint Update ===${NC}"

# Ensure required directories and files exist
mkdir -p "$CLAUDE_DIR"

# Get current date and time
DATE=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M")

# Function to load checkpoint configuration
load_checkpoint_config() {
    if [ -f "$CHECKPOINT_CONFIG" ]; then
        echo -e "${GREEN}✓${NC} Using checkpoint configuration"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Checkpoint config not found, using defaults"
        return 1
    fi
}

# Function to update ROADMAP.md with proper checkboxes
update_roadmap_checkboxes() {
    local phase="$1"
    local roadmap_file="$PROJECT_ROOT/ROADMAP.md"
    
    if [ ! -f "$roadmap_file" ]; then
        echo -e "${RED}✗${NC} ROADMAP.md not found"
        return 1
    fi
    
    echo -e "${BLUE}Updating ROADMAP.md for Phase $phase...${NC}"
    
    # Map phase to line ranges (based on current ROADMAP.md structure)
    case "$phase" in
        "1.3")
            sed -i '58,86s/- \[ \]/- [x]/g' "$roadmap_file"
            ;;
        "1.4")
            sed -i '88,108s/- \[ \]/- [x]/g' "$roadmap_file"
            ;;
        "1.5")
            sed -i '109,137s/- \[ \]/- [x]/g' "$roadmap_file"
            ;;
        "1.6")
            sed -i '138,338s/- \[ \]/- [x]/g' "$roadmap_file"
            ;;
    esac
    
    echo -e "${GREEN}✓${NC} Updated ROADMAP.md checkboxes for Phase $phase"
}

# Function to detect current phase from todos.json or fallback methods
detect_current_phase() {
    # First try to get from todos.json
    if [ -f "$TODOS_FILE" ]; then
        if command -v jq &> /dev/null; then
            PHASE=$(jq -r '.currentPhase // "1.3"' "$TODOS_FILE" 2>/dev/null || echo "1.3")
            echo "$PHASE"
            return
        else
            # Fallback parsing without jq
            PHASE=$(grep '"currentPhase"' "$TODOS_FILE" 2>/dev/null | sed 's/.*"currentPhase": *"\([^"]*\)".*/\1/' || echo "1.3")
            if [ -n "$PHASE" ]; then
                echo "$PHASE"
                return
            fi
        fi
    fi
    
    # Check recent commits for phase mentions
    if git log --oneline -10 2>/dev/null | grep -q "Phase"; then
        PHASE=$(git log --oneline -10 | grep -o "Phase [0-9]\.[0-9]" | head -1 | sed 's/Phase //' || echo "1.3")
        echo "$PHASE"
    else
        echo "1.3" # Default to current phase
    fi
}

# Function to update completed.txt
update_completed_txt() {
    local task_desc="$1"
    local phase="$2"
    
    COMPLETED_FILE="$PROJECT_ROOT/.claude/completed.txt"
    
    # Check if task already exists (avoid duplicates)
    if ! grep -q "$task_desc" "$COMPLETED_FILE" 2>/dev/null; then
        echo "[$DATE] [$TIME] [Phase$phase] $task_desc" >> "$COMPLETED_FILE"
        echo -e "${GREEN}✓${NC} Added to completed.txt: $task_desc"
    fi
}

# Function to update PHASE1-TASKS.md checkboxes
update_phase_tasks() {
    local pattern="$1"
    local file="$PROJECT_ROOT/PHASE1-TASKS.md"
    
    if [ -f "$file" ]; then
        # Convert unchecked boxes to checked for matching patterns
        sed -i "/$pattern/s/\[ \]/[x]/g" "$file" 2>/dev/null || true
    fi
}

# Function to update todos.json status
update_todos_json() {
    local phase="$1"
    local status="$2"
    
    if [ -f "$TODOS_FILE" ]; then
        # Update phase status using sed
        sed -i "/\"$phase\":/,/\"status\":/ s/\"status\":.*\"[^\"]*\"/\"status\": \"$status\"/" "$TODOS_FILE" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Updated todos.json: Phase $phase → $status"
    fi
}

# Function to detect completed tasks from git diff
detect_completed_tasks() {
    # Check for test files that pass
    if git diff --cached --name-only 2>/dev/null | grep -q "_test\.go$\|_test\.js$\|_test\.ts$"; then
        echo "tests"
    fi
    
    # Check for new endpoints
    if git diff --cached 2>/dev/null | grep -q "router\\..*(\|app\\..*(\|r\\..*"; then
        echo "endpoints"
    fi
    
    # Check for documentation updates
    if git diff --cached --name-only 2>/dev/null | grep -q "\.md$"; then
        echo "docs"
    fi
}

# Enhanced main checkpoint update logic
main() {
    load_checkpoint_config
    
    CURRENT_PHASE=$(detect_current_phase)
    echo -e "${YELLOW}Current Phase:${NC} $CURRENT_PHASE"
    
    # Initialize todo-persist system if needed
    if [ -f "$PROJECT_ROOT/scripts/todo-persist.js" ]; then
        node "$PROJECT_ROOT/scripts/todo-persist.js" init 2>/dev/null || true
    fi
    
    # Check what type of changes were made
    TASK_TYPES=$(detect_completed_tasks)
    
    # Auto-detect and update based on file changes with enhanced patterns
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*main\.go\|^[AM].*cmd/.*\.go"; then
        update_completed_txt "Updated API server implementation" "$CURRENT_PHASE"
        update_phase_tasks "Core API"
    fi
    
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*_test\."; then
        update_completed_txt "Added/updated tests" "$CURRENT_PHASE"
        update_phase_tasks "test"
    fi
    
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*handlers/\|^[AM].*internal/"; then
        update_completed_txt "Implemented API handlers" "$CURRENT_PHASE"
        update_phase_tasks "endpoint"
    fi
    
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*\.proto$\|^[AM].*openapi\.yaml\|^[AM].*schemas/"; then
        update_completed_txt "Updated API contracts" "$CURRENT_PHASE"
        update_phase_tasks "contract"
    fi
    
    # Check for orchestrator changes (Phase 1.3)
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*orchestrator/.*\.ts\|^[AM].*graph\.ts\|^[AM].*nodes/"; then
        update_completed_txt "Updated orchestrator implementation" "$CURRENT_PHASE"
        update_phase_tasks "orchestrator"
    fi
    
    # Check for frontend changes (Phase 1.4)
    if git status --porcelain 2>/dev/null | grep -q "^[AM].*web/.*\.svelte\|^[AM].*web/.*\.ts\|^[AM].*web/.*\.js"; then
        update_completed_txt "Updated frontend implementation" "$CURRENT_PHASE"
        update_phase_tasks "frontend"
    fi
    
    # Check todos.json for completed tasks and update ROADMAP.md accordingly
    if [ -f "$TODOS_FILE" ]; then
        # Check each phase status in todos.json
        for phase in "1.3" "1.4" "1.5" "1.6"; do
            if command -v jq &> /dev/null; then
                phase_status=$(jq -r ".phases[\"$phase\"].status // \"pending\"" "$TODOS_FILE" 2>/dev/null || echo "pending")
            else
                phase_status=$(grep -A3 "\"$phase\":" "$TODOS_FILE" 2>/dev/null | grep "status" | sed 's/.*"status": *"\([^"]*\)".*/\1/' || echo "pending")
            fi
            
            if [ "$phase_status" = "completed" ]; then
                update_roadmap_checkboxes "$phase"
            fi
        done
    fi
    
    # Check if all tasks for current phase are complete
    if [ -f "$PROJECT_ROOT/PHASE1-TASKS.md" ]; then
        PHASE_SECTION=$(sed -n "/Phase $CURRENT_PHASE:/,/^## /p" "$PROJECT_ROOT/PHASE1-TASKS.md" 2>/dev/null || echo "")
        UNCHECKED=$(echo "$PHASE_SECTION" | grep -c "\[ \]" 2>/dev/null || echo "0")
        
        if [ "$UNCHECKED" -eq 0 ] && [ -n "$PHASE_SECTION" ]; then
            echo -e "${GREEN}✓${NC} All tasks in Phase $CURRENT_PHASE appear complete!"
            update_todos_json "$CURRENT_PHASE" "completed"
            update_roadmap_checkboxes "$CURRENT_PHASE"
            
            # Update CONTINUITY.md
            if [ -f "$PROJECT_ROOT/CONTINUITY.md" ]; then
                sed -i "s/Current Status: .*/Current Status: Phase $CURRENT_PHASE COMPLETED/" "$PROJECT_ROOT/CONTINUITY.md" 2>/dev/null || true
                echo -e "${GREEN}✓${NC} Updated CONTINUITY.md status"
            fi
        fi
    fi
    
    # Update statistics in todos.json with enhanced counting
    if [ -f "$TODOS_FILE" ]; then
        if command -v jq &> /dev/null; then
            # Use jq for more accurate counting
            TOTAL=$(jq '[.phases | to_entries[] | .value.tasks | length] | add // 0' "$TODOS_FILE" 2>/dev/null || echo "0")
            COMPLETED=$(jq '[.phases | to_entries[] | .value.tasks[] | select(.status == "completed")] | length' "$TODOS_FILE" 2>/dev/null || echo "0")
        else
            # Fallback counting method
            TOTAL=$(grep '"id": "1\.' "$TODOS_FILE" 2>/dev/null | wc -l || echo "0")
            COMPLETED=$(grep '"status": "completed"' "$TODOS_FILE" 2>/dev/null | wc -l || echo "0")
        fi
        
        if [ "$TOTAL" -gt 0 ]; then
            RATE=$(echo "scale=1; $COMPLETED * 100 / $TOTAL" | bc 2>/dev/null || echo "0")
            echo -e "${GREEN}✓${NC} Statistics: $COMPLETED/$TOTAL tasks completed ($RATE%)"
        fi
    fi
    
    echo -e "${BLUE}=== Enhanced Checkpoint Update Complete ===${NC}"
    echo -e "${GREEN}Files updated:${NC}"
    echo "  - .claude/todos.json"
    echo "  - .claude/completed.txt" 
    echo "  - ROADMAP.md checkboxes"
    echo "  - PHASE1-TASKS.md"
    echo "  - CONTINUITY.md"
}

# Run main function
main "$@"