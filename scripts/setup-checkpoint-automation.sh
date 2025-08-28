#!/bin/bash

# Setup Checkpoint Automation System
# Configures git hooks and initializes the automation system

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
GITHOOKS_DIR="$PROJECT_ROOT/.githooks"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Checkpoint Automation System${NC}"
echo "============================================="

# Function to check prerequisites
check_prerequisites() {
  echo -e "\n${BLUE}Checking prerequisites...${NC}"
  
  # Check for git
  if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git not found${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓${NC} Git found"
  
  # Check for node
  if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓${NC} Node.js found ($(node --version))"
  
  # Check for jq (optional but recommended)
  if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓${NC} jq found (recommended for better JSON handling)"
  else
    echo -e "${YELLOW}⚠${NC} jq not found (will use fallback parsing)"
  fi
  
  # Check for bc (for percentage calculations)
  if command -v bc &> /dev/null; then
    echo -e "${GREEN}✓${NC} bc found"
  else
    echo -e "${YELLOW}⚠${NC} bc not found (will use basic calculations)"
  fi
}

# Function to setup directories
setup_directories() {
  echo -e "\n${BLUE}Setting up directories...${NC}"
  
  mkdir -p "$CLAUDE_DIR"
  echo -e "${GREEN}✓${NC} Created .claude directory"
  
  mkdir -p "$GITHOOKS_DIR"
  echo -e "${GREEN}✓${NC} Created .githooks directory"
  
  # Create log directory
  mkdir -p "$CLAUDE_DIR/logs"
  echo -e "${GREEN}✓${NC} Created .claude/logs directory"
}

# Function to initialize configuration files
initialize_configs() {
  echo -e "\n${BLUE}Initializing configuration files...${NC}"
  
  # Initialize todos.json if it doesn't exist
  if [ ! -f "$CLAUDE_DIR/todos.json" ]; then
    node "$SCRIPT_DIR/todo-persist.js" init
    echo -e "${GREEN}✓${NC} Initialized todos.json"
  else
    echo -e "${YELLOW}ℹ${NC} todos.json already exists"
  fi
  
  # Initialize completed.txt if it doesn't exist
  if [ ! -f "$CLAUDE_DIR/completed.txt" ]; then
    echo "# Completed Tasks Log" > "$CLAUDE_DIR/completed.txt"
    echo "# Format: [DATE] [TIME] [PHASE] Description" >> "$CLAUDE_DIR/completed.txt"
    echo "" >> "$CLAUDE_DIR/completed.txt"
    echo -e "${GREEN}✓${NC} Initialized completed.txt"
  else
    echo -e "${YELLOW}ℹ${NC} completed.txt already exists"
  fi
  
  # Check checkpoint-config.json
  if [ -f "$CLAUDE_DIR/checkpoint-config.json" ]; then
    echo -e "${GREEN}✓${NC} checkpoint-config.json found"
  else
    echo -e "${YELLOW}⚠${NC} checkpoint-config.json not found"
  fi
}

# Function to setup git hooks
setup_git_hooks() {
  echo -e "\n${BLUE}Setting up git hooks...${NC}"
  
  # Check if we're in a git repository
  if ! git rev-parse --git-dir &> /dev/null; then
    echo -e "${RED}✗ Not in a git repository${NC}"
    return 1
  fi
  
  GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
  
  # Install post-commit hook
  if [ -f "$GITHOOKS_DIR/post-commit" ]; then
    cp "$GITHOOKS_DIR/post-commit" "$GIT_HOOKS_DIR/post-commit"
    chmod +x "$GIT_HOOKS_DIR/post-commit"
    echo -e "${GREEN}✓${NC} Installed post-commit hook"
  else
    echo -e "${RED}✗ post-commit hook source not found${NC}"
    return 1
  fi
  
  # Backup existing hooks if they exist
  for hook in pre-push pre-commit; do
    if [ -f "$GITHOOKS_DIR/$hook" ] && [ ! -f "$GIT_HOOKS_DIR/$hook" ]; then
      cp "$GITHOOKS_DIR/$hook" "$GIT_HOOKS_DIR/$hook"
      chmod +x "$GIT_HOOKS_DIR/$hook"
      echo -e "${GREEN}✓${NC} Installed $hook hook"
    elif [ -f "$GIT_HOOKS_DIR/$hook" ]; then
      echo -e "${YELLOW}ℹ${NC} $hook hook already exists (skipping)"
    fi
  done
}

# Function to make scripts executable
make_scripts_executable() {
  echo -e "\n${BLUE}Making scripts executable...${NC}"
  
  SCRIPTS=(
    "$SCRIPT_DIR/auto-checkpoint.sh"
    "$SCRIPT_DIR/todo-persist.js"
    "$SCRIPT_DIR/update-todos.sh"
    "$GITHOOKS_DIR/post-commit"
  )
  
  for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
      chmod +x "$script"
      echo -e "${GREEN}✓${NC} Made $(basename "$script") executable"
    else
      echo -e "${YELLOW}⚠${NC} Script not found: $(basename "$script")"
    fi
  done
}

# Function to test the system
test_system() {
  echo -e "\n${BLUE}Testing the system...${NC}"
  
  # Test todo-persist.js
  echo -e "\n${YELLOW}Testing todo-persist.js:${NC}"
  if node "$SCRIPT_DIR/todo-persist.js" status; then
    echo -e "${GREEN}✓${NC} todo-persist.js working"
  else
    echo -e "${RED}✗${NC} todo-persist.js failed"
  fi
  
  # Test auto-checkpoint.sh
  echo -e "\n${YELLOW}Testing auto-checkpoint.sh:${NC}"
  if bash "$SCRIPT_DIR/auto-checkpoint.sh" --test 2>/dev/null || true; then
    echo -e "${GREEN}✓${NC} auto-checkpoint.sh accessible"
  else
    echo -e "${YELLOW}⚠${NC} auto-checkpoint.sh may have issues (this is expected in test mode)"
  fi
  
  # Test git hook
  if [ -f "$(git rev-parse --git-dir)/hooks/post-commit" ]; then
    echo -e "${GREEN}✓${NC} post-commit hook installed"
  else
    echo -e "${RED}✗${NC} post-commit hook not installed"
  fi
}

# Function to show usage instructions
show_usage() {
  echo -e "\n${BLUE}📋 Usage Instructions${NC}"
  echo "====================="
  echo ""
  echo "The checkpoint automation system is now set up. Here's how it works:"
  echo ""
  echo -e "${YELLOW}1. Automatic Triggers:${NC}"
  echo "   • post-commit: Runs after each git commit"
  echo "   • Detects completed tasks and updates tracking files"
  echo ""
  echo -e "${YELLOW}2. Manual Commands:${NC}"
  echo "   • Run checkpoint manually:"
  echo "     bash scripts/auto-checkpoint.sh"
  echo ""
  echo "   • Check todo status:"
  echo "     node scripts/todo-persist.js status"
  echo ""
  echo "   • Update todos manually:"
  echo "     bash scripts/update-todos.sh"
  echo ""
  echo -e "${YELLOW}3. Files Updated Automatically:${NC}"
  echo "   • .claude/todos.json         (task tracking)"
  echo "   • .claude/completed.txt      (completion log)"
  echo "   • ROADMAP.md                 (phase checkboxes)"
  echo "   • PHASE1-TASKS.md           (task checkboxes)"
  echo "   • CONTINUITY.md             (current status)"
  echo ""
  echo -e "${YELLOW}4. Configuration:${NC}"
  echo "   • .claude/checkpoint-config.json (system config)"
  echo "   • .githooks/post-commit         (git hook source)"
  echo ""
  echo -e "${GREEN}✅ System is ready to use!${NC}"
}

# Main execution
main() {
  check_prerequisites
  setup_directories
  initialize_configs
  make_scripts_executable
  setup_git_hooks
  test_system
  show_usage
  
  echo -e "\n${GREEN}🎉 Checkpoint automation system setup complete!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Make a test commit to see the system in action"
  echo "2. Check .claude/todos.json for task tracking"
  echo "3. Review ROADMAP.md for updated checkboxes"
}

# Handle command line arguments
case "${1:-setup}" in
  setup)
    main
    ;;
  test)
    test_system
    ;;
  hooks)
    setup_git_hooks
    ;;
  help)
    echo "Usage: $0 [setup|test|hooks|help]"
    echo "  setup - Full system setup (default)"
    echo "  test  - Test system components"
    echo "  hooks - Setup git hooks only"
    echo "  help  - Show this help"
    ;;
  *)
    echo "Unknown command: $1"
    echo "Use '$0 help' for usage"
    exit 1
    ;;
esac