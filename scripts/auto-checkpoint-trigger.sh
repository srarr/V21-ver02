#!/bin/bash

# Auto Checkpoint Trigger Script
# Provides functions and automation for checkpoint management

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to trigger checkpoint after task completion
after_task_complete() {
    local task_desc="${1:-task}"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Task Completed:${NC} $task_desc"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}🤖 Auto-triggering checkpoint manager...${NC}"
    echo ""
    
    # Try different methods to trigger checkpoint
    
    # Method 1: Check if in Claude Code session
    if [ -n "$CLAUDE_CODE_SESSION" ] || [ -n "$CLAUDE_SESSION_ID" ]; then
        echo -e "${CYAN}Detected Claude Code session${NC}"
        echo -e "${GREEN}➤ Please run:${NC} /agents checkpoint-manager \"update after $task_desc\""
        return 0
    fi
    
    # Method 2: Try Claude Code CLI (if available in future)
    if command -v claude-code >/dev/null 2>&1; then
        echo -e "${CYAN}Using Claude Code CLI...${NC}"
        claude-code run-agent checkpoint-manager "auto-update after $task_desc" 2>/dev/null || {
            echo -e "${YELLOW}CLI command failed, manual run required${NC}"
        }
        return 0
    fi
    
    # Method 3: Show prominent reminder
    show_checkpoint_required "$task_desc"
}

# Function to show checkpoint required message
show_checkpoint_required() {
    local context="${1:-recent changes}"
    
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚡ CHECKPOINT UPDATE REQUIRED${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Context:${NC} $context"
    echo ""
    echo -e "${GREEN}Required Action:${NC}"
    echo -e "  ${YELLOW}/agents checkpoint-manager \"update\"${NC}"
    echo ""
    echo -e "${CYAN}Why this matters:${NC}"
    echo "  • Keeps tracking files in sync"
    echo "  • Updates progress statistics"
    echo "  • Prevents future inconsistencies"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function for phase completion
after_phase_complete() {
    local phase="${1:-unknown}"
    
    echo ""
    echo -e "${GREEN}🎉 PHASE $phase COMPLETED!${NC}"
    after_task_complete "Phase $phase completion"
}

# Function for session start
on_session_start() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📋 Session Start - Checkpoint Verification${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Checking project status...${NC}"
    
    # Quick status check
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        local completed=$(grep '"status": "completed"' "$PROJECT_ROOT/.claude/todos.json" | wc -l)
        local total=$(grep '"id": "1\.' "$PROJECT_ROOT/.claude/todos.json" | wc -l)
        echo -e "${CYAN}Progress:${NC} $completed/$total tasks completed"
    fi
    
    echo ""
    echo -e "${GREEN}➤ Run checkpoint verification:${NC}"
    echo -e "  ${YELLOW}/agents checkpoint-manager \"session start check\"${NC}"
    echo ""
}

# Function for file change detection
on_file_changed() {
    local file="${1:-unknown}"
    
    case "$file" in
        *todos.json*|*PHASE1-TASKS.md*|*completed.txt*)
            echo -e "${YELLOW}📝 Tracking file changed:${NC} $file"
            after_task_complete "tracking file update"
            ;;
        *.go|*.ts|*.js|*.py|*.rs)
            echo -e "${CYAN}Code file changed:${NC} $file"
            echo -e "${CYAN}Consider running checkpoint after completing task${NC}"
            ;;
    esac
}

# Function to check if checkpoint needed
is_checkpoint_needed() {
    local reason=""
    
    # Check for recent changes
    if [ -d "$PROJECT_ROOT/.git" ]; then
        if git diff --name-only 2>/dev/null | grep -qE "(todos|TASKS|completed)"; then
            reason="tracking files modified"
        elif git log -1 --pretty=%B 2>/dev/null | grep -qiE "(complete|finish|done)"; then
            reason="completion detected in commit"
        fi
    fi
    
    if [ -n "$reason" ]; then
        echo "$reason"
        return 0
    fi
    
    return 1
}

# Main command handler
case "${1:-help}" in
    task-done)
        after_task_complete "${2:-task}"
        ;;
        
    phase-done)
        after_phase_complete "${2:-unknown}"
        ;;
        
    session-start)
        on_session_start
        ;;
        
    file-changed)
        on_file_changed "${2:-unknown}"
        ;;
        
    check)
        if reason=$(is_checkpoint_needed); then
            echo -e "${YELLOW}Checkpoint needed:${NC} $reason"
            show_checkpoint_required "$reason"
        else
            echo -e "${GREEN}✓${NC} Checkpoints appear up to date"
        fi
        ;;
        
    auto)
        # Full auto mode - detect and suggest
        echo -e "${CYAN}Auto-detecting checkpoint needs...${NC}"
        
        if reason=$(is_checkpoint_needed); then
            after_task_complete "auto-detected: $reason"
        else
            echo -e "${GREEN}✓${NC} No checkpoint update needed"
        fi
        ;;
        
    help|--help)
        echo "Usage: $0 [command] [context]"
        echo ""
        echo "Commands:"
        echo "  task-done [desc]     - After completing a task"
        echo "  phase-done [phase]   - After completing a phase"
        echo "  session-start        - At session beginning"
        echo "  file-changed [file]  - When file changes detected"
        echo "  check                - Check if checkpoint needed"
        echo "  auto                 - Auto-detect and suggest"
        echo "  help                 - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 task-done \"implemented API endpoint\""
        echo "  $0 phase-done \"1.3\""
        echo "  $0 session-start"
        echo ""
        echo "This script helps trigger checkpoint-manager at the right times."
        ;;
        
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac

# Export functions for use by other scripts
export -f after_task_complete
export -f after_phase_complete
export -f on_session_start
export -f show_checkpoint_required