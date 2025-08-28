#!/usr/bin/env bash

# Update Todo Tracking System
# This script syncs todo status across all tracking files

set -euo pipefail

PROJECT_ROOT="/mnt/c/New Claude Code/V21 Ver01"
TODOS_FILE="$PROJECT_ROOT/.claude/todos.json"
COMPLETED_FILE="$PROJECT_ROOT/.claude/completed.txt"
CONTEXT_FILE="$PROJECT_ROOT/.claude/context.json"
PHASE1_FILE="$PROJECT_ROOT/PHASE1-TASKS.md"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Todo Tracking System Update${NC}"
echo "================================"

# Function to get current timestamp
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to update JSON timestamp
update_json_timestamp() {
    local file=$1
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    if command -v jq &> /dev/null; then
        # Use jq if available
        jq ".lastUpdated = \"$timestamp\"" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        echo -e "${GREEN}✓${NC} Updated timestamp in $(basename $file)"
    else
        # Manual update if jq not available
        sed -i "s/\"lastUpdated\": \".*\"/\"lastUpdated\": \"$timestamp\"/" "$file"
        echo -e "${YELLOW}⚠${NC} Updated timestamp in $(basename $file) (without jq)"
    fi
}

# Function to count tasks
count_tasks() {
    local completed=$(grep -c "^\[x\]" "$PHASE1_FILE" 2>/dev/null || echo 0)
    local pending=$(grep -c "^\[ \]" "$PHASE1_FILE" 2>/dev/null || echo 0)
    local total=$((completed + pending))
    
    echo -e "${BLUE}Task Statistics:${NC}"
    echo "  Total:     $total"
    echo "  Completed: $completed"
    echo "  Pending:   $pending"
    if [ $total -gt 0 ]; then
        local percent=$((completed * 100 / total))
        echo "  Progress:  ${percent}%"
    fi
}

# Function to get next tasks
get_next_tasks() {
    echo -e "\n${BLUE}Next 3 Tasks:${NC}"
    grep "^\[ \]" "$PHASE1_FILE" 2>/dev/null | head -3 | while read line; do
        echo "  • ${line:4}"
    done
}

# Function to add completed task
add_completed_task() {
    local phase=$1
    local task=$2
    local timestamp=$(date +"%Y-%m-%d")
    local time=$(date +"%H:%M")
    
    echo "[$timestamp] [$time] [$phase] $task" >> "$COMPLETED_FILE"
    echo -e "${GREEN}✓${NC} Added to completed.txt: $task"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    # Update timestamps
    echo -e "\n${BLUE}Updating timestamps...${NC}"
    update_json_timestamp "$TODOS_FILE"
    update_json_timestamp "$CONTEXT_FILE"
    
    # Show statistics
    echo ""
    count_tasks
    
    # Show next tasks
    get_next_tasks
    
    # Check for recent completions
    echo -e "\n${BLUE}Recent Completions:${NC}"
    tail -5 "$COMPLETED_FILE" | while read line; do
        echo "  $line"
    done
    
    echo -e "\n${GREEN}✅ Todo tracking system updated!${NC}"
    echo ""
    echo "Files updated:"
    echo "  • .claude/todos.json"
    echo "  • .claude/context.json"
    echo "  • .claude/completed.txt"
    echo "  • PHASE1-TASKS.md"
}

# Handle command line arguments
case "${1:-status}" in
    status)
        main
        ;;
    add)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 add <phase> <task description>"
            exit 1
        fi
        add_completed_task "$2" "${@:3}"
        ;;
    help)
        echo "Usage: $0 [status|add|help]"
        echo "  status - Show current todo status (default)"
        echo "  add <phase> <task> - Add completed task"
        echo "  help - Show this help"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac