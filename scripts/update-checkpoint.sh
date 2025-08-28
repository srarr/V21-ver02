#!/usr/bin/env bash

# Auto-update checkpoints in ROADMAP.md and other tracking files
# Usage: ./scripts/update-checkpoint.sh <phase> <task> [completed|pending]

set -euo pipefail

PROJECT_ROOT="/mnt/c/New Claude Code/V21 Ver01"
ROADMAP="$PROJECT_ROOT/ROADMAP.md"
PHASE1_TASKS="$PROJECT_ROOT/PHASE1-TASKS.md"
TODOS_JSON="$PROJECT_ROOT/.claude/todos.json"
COMPLETED_TXT="$PROJECT_ROOT/.claude/completed.txt"
CONTINUITY="$PROJECT_ROOT/CONTINUITY.md"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Get timestamp
TIMESTAMP=$(date +"%Y-%m-%d")
TIME=$(date +"%H:%M")

# Function to mark task as completed in markdown
mark_completed() {
    local file=$1
    local task=$2
    
    # Change [ ] to [x] and add ✅
    sed -i "s/- \[ \] $task/- [x] $task ✅/g" "$file"
    echo -e "${GREEN}✓${NC} Marked completed in $(basename $file): $task"
}

# Function to mark task as pending in markdown
mark_pending() {
    local file=$1
    local task=$2
    
    # Change [x] to [ ] and remove ✅
    sed -i "s/- \[x\] $task.*/- [ ] $task/g" "$file"
    echo -e "${YELLOW}○${NC} Marked pending in $(basename $file): $task"
}

# Function to add to completed.txt
add_to_completed() {
    local phase=$1
    local task=$2
    
    echo "[$TIMESTAMP] [$TIME] [$phase] $task" >> "$COMPLETED_TXT"
    echo -e "${GREEN}✓${NC} Added to completed.txt"
}

# Function to update phase status
update_phase_status() {
    local phase=$1
    local status=$2
    
    # Update in CONTINUITY.md
    sed -i "s/Current Status:.*/Current Status: Phase $phase $status/g" "$CONTINUITY"
    echo -e "${BLUE}↻${NC} Updated phase status to: $phase $status"
}

# Function to count progress
show_progress() {
    echo ""
    echo -e "${BLUE}📊 Progress Statistics:${NC}"
    
    # Count in ROADMAP.md
    if [ -f "$ROADMAP" ]; then
        local completed=$(grep -c "^\- \[x\]" "$ROADMAP" 2>/dev/null || echo 0)
        local pending=$(grep -c "^\- \[ \]" "$ROADMAP" 2>/dev/null || echo 0)
        local total=$((completed + pending))
        
        if [ $total -gt 0 ]; then
            local percent=$((completed * 100 / total))
            echo "  ROADMAP.md: $completed/$total ($percent%)"
        fi
    fi
    
    # Count in PHASE1-TASKS.md
    if [ -f "$PHASE1_TASKS" ]; then
        local completed=$(grep -c "^\- \[x\]" "$PHASE1_TASKS" 2>/dev/null || echo 0)
        local pending=$(grep -c "^\- \[ \]" "$PHASE1_TASKS" 2>/dev/null || echo 0)
        local total=$((completed + pending))
        
        if [ $total -gt 0 ]; then
            local percent=$((completed * 100 / total))
            echo "  PHASE1-TASKS.md: $completed/$total ($percent%)"
        fi
    fi
}

# Function to update JSON timestamp
update_json_timestamps() {
    if command -v jq &> /dev/null; then
        # Update todos.json
        if [ -f "$TODOS_JSON" ]; then
            jq ".lastUpdated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$TODOS_JSON" > "$TODOS_JSON.tmp" && mv "$TODOS_JSON.tmp" "$TODOS_JSON"
            echo -e "${GREEN}✓${NC} Updated todos.json timestamp"
        fi
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  complete <phase> <task>  - Mark task as completed"
    echo "  pending <phase> <task>   - Mark task as pending"
    echo "  phase <phase> <status>   - Update phase status"
    echo "  progress                 - Show progress statistics"
    echo "  sync                     - Sync all tracking files"
    echo ""
    echo "Examples:"
    echo "  $0 complete 1.2 \"GET /healthz\""
    echo "  $0 phase 1.2 \"IN PROGRESS\""
    echo "  $0 progress"
}

# Main logic
case "${1:-help}" in
    complete)
        if [ $# -lt 3 ]; then
            echo -e "${RED}Error:${NC} Missing arguments"
            show_usage
            exit 1
        fi
        
        PHASE="$2"
        TASK="${@:3}"
        
        echo -e "${BLUE}Marking task as completed...${NC}"
        echo "  Phase: $PHASE"
        echo "  Task: $TASK"
        echo ""
        
        # Update files
        mark_completed "$ROADMAP" "$TASK"
        mark_completed "$PHASE1_TASKS" "$TASK"
        add_to_completed "Phase$PHASE" "$TASK"
        update_json_timestamps
        
        show_progress
        ;;
        
    pending)
        if [ $# -lt 3 ]; then
            echo -e "${RED}Error:${NC} Missing arguments"
            show_usage
            exit 1
        fi
        
        PHASE="$2"
        TASK="${@:3}"
        
        echo -e "${YELLOW}Marking task as pending...${NC}"
        echo "  Phase: $PHASE"
        echo "  Task: $TASK"
        echo ""
        
        mark_pending "$ROADMAP" "$TASK"
        mark_pending "$PHASE1_TASKS" "$TASK"
        update_json_timestamps
        
        show_progress
        ;;
        
    phase)
        if [ $# -lt 3 ]; then
            echo -e "${RED}Error:${NC} Missing arguments"
            show_usage
            exit 1
        fi
        
        PHASE="$2"
        STATUS="${@:3}"
        
        update_phase_status "$PHASE" "$STATUS"
        update_json_timestamps
        ;;
        
    progress)
        show_progress
        ;;
        
    sync)
        echo -e "${BLUE}Syncing all tracking files...${NC}"
        update_json_timestamps
        show_progress
        echo -e "${GREEN}✅ Sync complete!${NC}"
        ;;
        
    help|*)
        show_usage
        ;;
esac

echo ""
echo -e "${GREEN}✅ Checkpoint update complete!${NC}"