#!/bin/bash

# Checkpoint Wrapper Script
# Helps determine when to run checkpoint-manager agent

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if should run checkpoint
should_run_checkpoint() {
    local reason=""
    
    # Check if any implementation files changed
    if git diff --cached --name-only 2>/dev/null | grep -qE "\.(go|ts|tsx|py|rs|js|jsx)$"; then
        reason="code changes detected"
        echo "$reason"
        return 0
    fi
    
    # Check if any tracking files changed
    if git diff --cached --name-only 2>/dev/null | grep -qE "(todos\.json|PHASE1-TASKS\.md|completed\.txt|CONTINUITY\.md)"; then
        reason="tracking files modified"
        echo "$reason"
        return 0
    fi
    
    # Check if commit message mentions phase or completion
    if git log -1 --pretty=%B 2>/dev/null | grep -iE "phase|complete|finish|done|implement|fix"; then
        reason="completion keyword in commit"
        echo "$reason"
        return 0
    fi
    
    # Check if we're in middle of a phase (has pending tasks)
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        local current_phase=$(grep '"status": "pending"' "$PROJECT_ROOT/.claude/todos.json" | head -1)
        if [ -n "$current_phase" ]; then
            reason="active phase detected"
            echo "$reason"
            return 0
        fi
    fi
    
    return 1
}

# Function to detect current phase
detect_current_phase() {
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        # Find first pending phase
        for phase in "1.1" "1.2" "1.3" "1.4" "1.5" "1.6"; do
            local status=$(grep "\"$phase\"" -A2 "$PROJECT_ROOT/.claude/todos.json" | grep '"status":' | head -1 | sed 's/.*"status".*"\([^"]*\)".*/\1/')
            if [ "$status" = "pending" ]; then
                echo "$phase"
                return
            fi
        done
    fi
    echo "unknown"
}

# Function to show checkpoint reminder
show_checkpoint_reminder() {
    local reason="$1"
    local phase=$(detect_current_phase)
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 Checkpoint Manager Reminder${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Trigger:${NC} $reason"
    
    if [ "$phase" != "unknown" ]; then
        echo -e "${CYAN}Current Phase:${NC} $phase"
    fi
    
    echo ""
    echo -e "${GREEN}Recommended command:${NC}"
    echo -e "  ${YELLOW}/agents checkpoint-manager \"verify and fix\"${NC}"
    echo ""
    echo -e "${CYAN}Other options:${NC}"
    echo "  • Quick check:  /agents checkpoint-manager \"status\""
    echo "  • Full repair:  /agents checkpoint-manager \"repair all\""
    echo "  • Report only:  /agents checkpoint-manager \"report\""
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to check for common issues
quick_check() {
    echo -e "${CYAN}Quick check for obvious issues...${NC}"
    
    local issues=0
    
    # Check if todos.json exists
    if [ ! -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        echo -e "${YELLOW}⚠${NC}  todos.json missing"
        issues=$((issues + 1))
    fi
    
    # Check for phase/task mismatch (simple check)
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        # Check if Phase 1.3 or later has completed tasks but pending status
        for phase in "1.3" "1.4" "1.5" "1.6"; do
            local has_completed=$(grep "\"$phase\"" -A50 "$PROJECT_ROOT/.claude/todos.json" | grep '"status": "completed"' | wc -l || echo "0")
            has_completed=$(echo "$has_completed" | tr -d '\n')
            if [ "$has_completed" -gt 1 ]; then
                echo -e "${YELLOW}⚠${NC}  Phase $phase may have inconsistencies"
                issues=$((issues + 1))
            fi
        done
    fi
    
    if [ "$issues" -gt 0 ]; then
        echo -e "${YELLOW}Found $issues potential issues${NC}"
        echo -e "${GREEN}→ Run checkpoint-manager to fix${NC}"
    else
        echo -e "${GREEN}✓${NC} No obvious issues detected"
    fi
}

# Main logic
main() {
    case "${1:-check}" in
        check|--check)
            # Check if should run and show reminder
            if reason=$(should_run_checkpoint); then
                show_checkpoint_reminder "$reason"
                quick_check
                exit 0
            else
                echo -e "${GREEN}✓${NC} No checkpoint update needed"
                exit 0
            fi
            ;;
            
        force|--force)
            # Always show reminder
            show_checkpoint_reminder "manual trigger"
            quick_check
            ;;
            
        status|--status)
            # Just show current status
            echo -e "${CYAN}Current Phase:${NC} $(detect_current_phase)"
            quick_check
            ;;
            
        help|--help)
            echo "Usage: $0 [check|force|status|help]"
            echo ""
            echo "Commands:"
            echo "  check   - Check if checkpoint update is needed (default)"
            echo "  force   - Force show checkpoint reminder"
            echo "  status  - Show current phase and quick check"
            echo "  help    - Show this help message"
            echo ""
            echo "This script helps determine when to run the checkpoint-manager agent."
            echo "It's called automatically by Git hooks but can also be run manually."
            ;;
            
        *)
            echo "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"