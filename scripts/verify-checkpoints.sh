#!/bin/bash

# Checkpoint Verification Script
# Ensures consistency across all tracking files

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Checkpoint Consistency Verification ===${NC}"
echo ""

# Track issues found
ISSUES_FOUND=0
WARNINGS=0

# Function to check file exists
check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description exists"
        return 0
    else
        echo -e "${RED}✗${NC} $description missing: $file"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
        return 1
    fi
}

# Function to check phase consistency
check_phase_consistency() {
    echo -e "\n${CYAN}Checking Phase Status Consistency...${NC}"
    
    # Get Phase 1.2 status from different sources
    local todos_status=""
    local tasks_status=""
    local continuity_status=""
    
    # Check todos.json
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        todos_status=$(grep -A2 '"1.2"' "$PROJECT_ROOT/.claude/todos.json" | grep '"status"' | head -1 | sed 's/.*"status".*"\([^"]*\)".*/\1/' || echo "error")
        echo "  todos.json Phase 1.2: $todos_status"
    fi
    
    # Check PHASE1-TASKS.md
    if [ -f "$PROJECT_ROOT/PHASE1-TASKS.md" ]; then
        if grep -q "## ✅ Phase 1.2.*COMPLETED" "$PROJECT_ROOT/PHASE1-TASKS.md"; then
            tasks_status="completed"
        elif grep -q "Phase 1.2.*PENDING" "$PROJECT_ROOT/PHASE1-TASKS.md"; then
            tasks_status="pending"
        else
            tasks_status="unknown"
        fi
        echo "  PHASE1-TASKS.md Phase 1.2: $tasks_status"
    fi
    
    # Check CONTINUITY.md
    if [ -f "$PROJECT_ROOT/CONTINUITY.md" ]; then
        if grep -q "Phase 1.2 COMPLETED" "$PROJECT_ROOT/CONTINUITY.md"; then
            continuity_status="completed"
        else
            continuity_status="pending"
        fi
        echo "  CONTINUITY.md Phase 1.2: $continuity_status"
    fi
    
    # Verify consistency
    if [ "$todos_status" = "$tasks_status" ] && [ "$tasks_status" = "$continuity_status" ]; then
        echo -e "${GREEN}✓${NC} Phase status is consistent across all files"
    else
        echo -e "${RED}✗${NC} Phase status inconsistency detected!"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
}

# Function to check task counts
check_task_counts() {
    echo -e "\n${CYAN}Checking Task Counts...${NC}"
    
    if [ -f "$PROJECT_ROOT/.claude/todos.json" ]; then
        # Count tasks in todos.json (without jq) - only count actual task items
        local todos_total=$(grep '"id": "1\.' "$PROJECT_ROOT/.claude/todos.json" | wc -l)
        
        # Count completed tasks properly - simpler approach
        local todos_completed=$(grep '"id": "1\.' -A2 "$PROJECT_ROOT/.claude/todos.json" | \
            grep -c '"status": "completed"' || echo "0")
        
        echo "  todos.json: $todos_completed/$todos_total completed"
        
        # Count checkboxes in PHASE1-TASKS.md
        if [ -f "$PROJECT_ROOT/PHASE1-TASKS.md" ]; then
            local tasks_checked=$(grep -c "\[x\]" "$PROJECT_ROOT/PHASE1-TASKS.md" || echo "0")
            local tasks_unchecked=$(grep -c "\[ \]" "$PROJECT_ROOT/PHASE1-TASKS.md" || echo "0")
            local tasks_total=$((tasks_checked + tasks_unchecked))
            
            echo "  PHASE1-TASKS.md: $tasks_checked/$tasks_total checked"
            
            # Compare counts (allow small differences due to formatting)
            todos_completed=$(echo "$todos_completed" | tr -d '\n')
            tasks_checked=$(echo "$tasks_checked" | tr -d '\n')
            
            if [ "$todos_completed" -gt 0 ] || [ "$tasks_checked" -gt 0 ]; then
                local diff=$((todos_completed > tasks_checked ? todos_completed - tasks_checked : tasks_checked - todos_completed))
                if [ "$diff" -gt 2 ]; then
                    echo -e "${YELLOW}⚠${NC}  Task count mismatch between files"
                    WARNINGS=$((WARNINGS + 1))
                else
                    echo -e "${GREEN}✓${NC} Task counts are consistent"
                fi
            fi
        fi
    fi
}

# Function to check completed.txt entries
check_completed_entries() {
    echo -e "\n${CYAN}Checking Completed Entries...${NC}"
    
    if [ -f "$PROJECT_ROOT/.claude/completed.txt" ]; then
        # Count Phase 1.2 entries
        local phase12_entries=$(grep -c "\[Phase1.2\]" "$PROJECT_ROOT/.claude/completed.txt" || echo "0")
        echo "  Phase 1.2 entries in completed.txt: $phase12_entries"
        
        if [ "$phase12_entries" -ge 10 ]; then
            echo -e "${GREEN}✓${NC} Phase 1.2 has sufficient entries in completed.txt"
        else
            echo -e "${YELLOW}⚠${NC}  Phase 1.2 has only $phase12_entries entries (expected ~15)"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # Check for duplicate entries
        local duplicates=$(sort "$PROJECT_ROOT/.claude/completed.txt" | uniq -d | wc -l)
        if [ "$duplicates" -gt 0 ]; then
            echo -e "${YELLOW}⚠${NC}  Found $duplicates duplicate entries in completed.txt"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Function to check file timestamps
check_file_timestamps() {
    echo -e "\n${CYAN}Checking File Update Times...${NC}"
    
    local latest_commit=$(git log -1 --format="%ai" 2>/dev/null || echo "unknown")
    echo "  Latest commit: $latest_commit"
    
    # Check when tracking files were last modified
    for file in ".claude/todos.json" ".claude/completed.txt" "PHASE1-TASKS.md" "CONTINUITY.md"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            local modified=$(stat -c %y "$PROJECT_ROOT/$file" 2>/dev/null | cut -d' ' -f1-2 || echo "unknown")
            echo "  $file: $modified"
        fi
    done
}

# Function to verify required structure
verify_project_structure() {
    echo -e "\n${CYAN}Verifying Project Structure...${NC}"
    
    # Required directories
    local dirs=("apps/api" "apps/web" "apps/orchestrator" "contracts" ".claude" "scripts")
    for dir in "${dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            echo -e "${GREEN}✓${NC} $dir/"
        else
            echo -e "${YELLOW}⚠${NC}  $dir/ missing"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
    
    # Required tracking files
    check_file_exists "$PROJECT_ROOT/.claude/todos.json" "Todo tracking"
    check_file_exists "$PROJECT_ROOT/.claude/completed.txt" "Completed tasks log"
    check_file_exists "$PROJECT_ROOT/PHASE1-TASKS.md" "Phase 1 task list"
    check_file_exists "$PROJECT_ROOT/CONTINUITY.md" "Continuity guide"
}

# Function to check Git hooks
check_git_hooks() {
    echo -e "\n${CYAN}Checking Git Hooks...${NC}"
    
    if [ -f "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
        if [ -x "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
            echo -e "${GREEN}✓${NC} Pre-commit hook installed and executable"
        else
            echo -e "${YELLOW}⚠${NC}  Pre-commit hook not executable"
            echo "  Fix with: chmod +x $PROJECT_ROOT/.git/hooks/pre-commit"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Pre-commit hook not installed"
        echo "  Install with: ./scripts/setup-git-hooks.sh"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if [ -f "$PROJECT_ROOT/.git/hooks/post-commit" ]; then
        if [ -x "$PROJECT_ROOT/.git/hooks/post-commit" ]; then
            echo -e "${GREEN}✓${NC} Post-commit hook installed and executable"
        else
            echo -e "${YELLOW}⚠${NC}  Post-commit hook not executable"
            echo "  Fix with: chmod +x $PROJECT_ROOT/.git/hooks/post-commit"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Post-commit hook not installed"
        WARNINGS=$((WARNINGS + 1))
    fi
}

# Function to suggest fixes
suggest_fixes() {
    if [ "$ISSUES_FOUND" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
        echo -e "\n${YELLOW}Suggested Fixes:${NC}"
        
        if [ "$ISSUES_FOUND" -gt 0 ]; then
            echo -e "${RED}Critical issues found that need immediate attention:${NC}"
            echo "  1. Run: ./scripts/auto-checkpoint.sh"
            echo "  2. Manually verify and update inconsistent files"
            echo "  3. Commit the fixes"
        fi
        
        if [ "$WARNINGS" -gt 0 ]; then
            echo -e "${YELLOW}Warnings that should be addressed:${NC}"
            echo "  1. Install Git hooks: ./scripts/setup-git-hooks.sh"
            echo "  2. Review and update task counts"
            echo "  3. Check for missing directories"
        fi
    fi
}

# Main verification
main() {
    echo "Project Root: $PROJECT_ROOT"
    echo ""
    
    # Run all checks
    verify_project_structure
    check_phase_consistency
    check_task_counts
    check_completed_entries
    check_file_timestamps
    check_git_hooks
    
    # Summary
    echo -e "\n${BLUE}=== Verification Summary ===${NC}"
    
    if [ "$ISSUES_FOUND" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}✓ All checkpoints are consistent!${NC}"
        echo -e "${GREEN}No issues found.${NC}"
    else
        echo -e "${RED}Issues Found: $ISSUES_FOUND${NC}"
        echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
        
        suggest_fixes
    fi
    
    # Return non-zero if critical issues found
    exit $ISSUES_FOUND
}

# Run main function
main "$@"