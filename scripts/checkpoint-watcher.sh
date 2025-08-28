#!/bin/bash

# Checkpoint Watcher Script
# Monitors file changes and triggers checkpoint reminders

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

# PID file for managing the watcher
PID_FILE="$PROJECT_ROOT/.claude/checkpoint-watcher.pid"

# Function to start the watcher
start_watcher() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}📡 Starting Checkpoint Watcher${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC}  Watcher already running (PID: $OLD_PID)"
            echo "Use '$0 stop' to stop it first"
            exit 1
        fi
    fi
    
    # Check if inotifywait is available
    if ! command -v inotifywait >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC}  inotifywait not installed"
        echo "Install with: sudo apt-get install inotify-tools"
        echo ""
        echo "Alternative: Use polling mode"
        start_polling_watcher
        return
    fi
    
    # Start file watcher in background
    (
        echo $$ > "$PID_FILE"
        echo -e "${GREEN}✓${NC} Watcher started (PID: $$)"
        echo "Monitoring: todos.json, PHASE1-TASKS.md, completed.txt"
        echo ""
        
        # Watch for file changes
        inotifywait -m -r -e modify,create \
            --include "todos\.json|PHASE1-TASKS\.md|completed\.txt" \
            "$PROJECT_ROOT/.claude" \
            "$PROJECT_ROOT" 2>/dev/null | \
        while read path action file; do
            handle_file_change "$file" "$action"
        done
    ) &
    
    WATCHER_PID=$!
    echo $WATCHER_PID > "$PID_FILE"
    echo -e "${GREEN}✓${NC} Background watcher started (PID: $WATCHER_PID)"
    echo "Stop with: $0 stop"
}

# Function for polling mode (fallback)
start_polling_watcher() {
    echo -e "${CYAN}Starting in polling mode (checking every 30 seconds)${NC}"
    
    (
        echo $$ > "$PID_FILE"
        
        # Store initial checksums
        declare -A checksums
        checksums["todos"]=$(md5sum "$PROJECT_ROOT/.claude/todos.json" 2>/dev/null | cut -d' ' -f1)
        checksums["tasks"]=$(md5sum "$PROJECT_ROOT/PHASE1-TASKS.md" 2>/dev/null | cut -d' ' -f1)
        checksums["completed"]=$(md5sum "$PROJECT_ROOT/.claude/completed.txt" 2>/dev/null | cut -d' ' -f1)
        
        while true; do
            sleep 30
            
            # Check for changes
            for file in todos tasks completed; do
                case $file in
                    todos) filepath="$PROJECT_ROOT/.claude/todos.json" ;;
                    tasks) filepath="$PROJECT_ROOT/PHASE1-TASKS.md" ;;
                    completed) filepath="$PROJECT_ROOT/.claude/completed.txt" ;;
                esac
                
                if [ -f "$filepath" ]; then
                    current=$(md5sum "$filepath" 2>/dev/null | cut -d' ' -f1)
                    if [ "${checksums[$file]}" != "$current" ]; then
                        echo -e "${YELLOW}📝 Change detected:${NC} $(basename "$filepath")"
                        handle_file_change "$(basename "$filepath")" "modified"
                        checksums[$file]="$current"
                    fi
                fi
            done
        done
    ) &
    
    WATCHER_PID=$!
    echo $WATCHER_PID > "$PID_FILE"
    echo -e "${GREEN}✓${NC} Polling watcher started (PID: $WATCHER_PID)"
}

# Function to handle file changes
handle_file_change() {
    local file="$1"
    local action="$2"
    
    # Ignore temporary files
    case "$file" in
        *.tmp|*.swp|*~) return ;;
    esac
    
    # Get current time
    TIME=$(date +"%H:%M:%S")
    
    echo ""
    echo -e "${YELLOW}[$TIME] File $action:${NC} $file"
    
    case "$file" in
        todos.json|PHASE1-TASKS.md|completed.txt)
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}📋 CHECKPOINT UPDATE NEEDED${NC}"
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${GREEN}Tracking file modified.${NC}"
            echo -e "${YELLOW}Run:${NC} /agents checkpoint-manager \"sync after $file change\""
            echo ""
            
            # Send desktop notification if available
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "Checkpoint Update Needed" \
                    "File changed: $file\nRun checkpoint-manager" \
                    -i dialog-warning 2>/dev/null || true
            fi
            ;;
            
        *.go|*.ts|*.js|*.py|*.rs)
            echo -e "${CYAN}Code file modified${NC}"
            echo "Consider running checkpoint after completing your task"
            ;;
    esac
}

# Function to stop the watcher
stop_watcher() {
    echo -e "${CYAN}Stopping checkpoint watcher...${NC}"
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            echo -e "${GREEN}✓${NC} Watcher stopped (PID: $PID)"
        else
            echo -e "${YELLOW}⚠${NC}  Watcher not running"
        fi
        rm -f "$PID_FILE"
    else
        echo -e "${YELLOW}⚠${NC}  No watcher PID file found"
    fi
}

# Function to check watcher status
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Watcher is running (PID: $PID)"
            echo ""
            echo "Monitoring files:"
            echo "  • .claude/todos.json"
            echo "  • PHASE1-TASKS.md"
            echo "  • .claude/completed.txt"
        else
            echo -e "${YELLOW}⚠${NC}  Watcher PID file exists but process not running"
            echo "Run '$0 start' to restart"
        fi
    else
        echo -e "${YELLOW}⚠${NC}  Watcher is not running"
        echo "Run '$0 start' to begin monitoring"
    fi
}

# Main command handler
case "${1:-status}" in
    start)
        start_watcher
        ;;
        
    stop)
        stop_watcher
        ;;
        
    restart)
        stop_watcher
        sleep 1
        start_watcher
        ;;
        
    status)
        check_status
        ;;
        
    test)
        # Test mode - trigger a change detection
        echo -e "${CYAN}Testing change detection...${NC}"
        handle_file_change "todos.json" "test-modified"
        ;;
        
    help|--help)
        echo "Usage: $0 [start|stop|restart|status|test|help]"
        echo ""
        echo "Commands:"
        echo "  start    - Start monitoring file changes"
        echo "  stop     - Stop the watcher"
        echo "  restart  - Restart the watcher"
        echo "  status   - Check if watcher is running"
        echo "  test     - Test change detection"
        echo "  help     - Show this help"
        echo ""
        echo "This script monitors tracking files and alerts when"
        echo "checkpoint-manager should be run."
        echo ""
        echo "Files monitored:"
        echo "  • .claude/todos.json"
        echo "  • PHASE1-TASKS.md"
        echo "  • .claude/completed.txt"
        ;;
        
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage"
        exit 1
        ;;
esac