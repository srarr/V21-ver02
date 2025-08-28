#!/bin/bash

# Git Hooks Setup Script
# One-time installation of checkpoint automation hooks

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

echo -e "${BLUE}=== Heliox ATLAS Git Hooks Setup ===${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo -e "${RED}✗ Not in a Git repository!${NC}"
    echo "Please run this script from the project root"
    exit 1
fi

# Function to install a hook
install_hook() {
    local hook_name="$1"
    local hook_file="$PROJECT_ROOT/.git/hooks/$hook_name"
    
    echo -e "${CYAN}Installing $hook_name hook...${NC}"
    
    # Check if hook already exists
    if [ -f "$hook_file" ]; then
        # Check if it's our hook
        if grep -q "Heliox ATLAS" "$hook_file" 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC}  $hook_name hook already installed (updating)"
        else
            # Backup existing hook
            echo -e "${YELLOW}⚠${NC}  Existing $hook_name hook found, creating backup"
            mv "$hook_file" "${hook_file}.backup.$(date +%Y%m%d%H%M%S)"
        fi
    fi
    
    # Copy hook from current directory if it exists
    if [ -f "$PROJECT_ROOT/.git/hooks/$hook_name" ]; then
        chmod +x "$hook_file"
        echo -e "${GREEN}✓${NC} $hook_name hook installed"
    else
        echo -e "${RED}✗${NC} $hook_name hook file not found"
        return 1
    fi
}

# Function to make scripts executable
make_scripts_executable() {
    echo -e "\n${CYAN}Making scripts executable...${NC}"
    
    # Checkpoint scripts
    local scripts=(
        "scripts/auto-checkpoint.sh"
        "scripts/verify-checkpoints.sh"
        "scripts/update-checkpoint.sh"
        "scripts/setup-git-hooks.sh"
        "scripts/check-prereqs.sh"
        "scripts/quick-start.sh"
        "start-heliox.sh"
        "setup-wsl-aliases.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_ROOT/$script" ]; then
            chmod +x "$PROJECT_ROOT/$script"
            echo -e "${GREEN}✓${NC} $script"
        fi
    done
}

# Function to test hooks
test_hooks() {
    echo -e "\n${CYAN}Testing hooks configuration...${NC}"
    
    # Test pre-commit hook
    if [ -x "$PROJECT_ROOT/.git/hooks/pre-commit" ]; then
        echo -e "${GREEN}✓${NC} Pre-commit hook is executable"
    else
        echo -e "${RED}✗${NC} Pre-commit hook not executable"
        return 1
    fi
    
    # Test post-commit hook
    if [ -x "$PROJECT_ROOT/.git/hooks/post-commit" ]; then
        echo -e "${GREEN}✓${NC} Post-commit hook is executable"
    else
        echo -e "${RED}✗${NC} Post-commit hook not executable"
        return 1
    fi
    
    # Verify checkpoint scripts exist
    if [ -f "$PROJECT_ROOT/scripts/auto-checkpoint.sh" ]; then
        echo -e "${GREEN}✓${NC} auto-checkpoint.sh found"
    else
        echo -e "${RED}✗${NC} auto-checkpoint.sh missing"
        return 1
    fi
    
    if [ -f "$PROJECT_ROOT/scripts/verify-checkpoints.sh" ]; then
        echo -e "${GREEN}✓${NC} verify-checkpoints.sh found"
    else
        echo -e "${RED}✗${NC} verify-checkpoints.sh missing"
        return 1
    fi
}

# Function to create sample git config
setup_git_config() {
    echo -e "\n${CYAN}Setting up Git configuration...${NC}"
    
    # Check if user wants to enable auto-checkpoint on every commit
    echo -e "${YELLOW}Enable automatic checkpoint updates on every commit? (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Add git alias for checkpoint commit
        git config --local alias.checkpoint '!bash -c "git add -A && $PROJECT_ROOT/scripts/auto-checkpoint.sh && git commit"'
        echo -e "${GREEN}✓${NC} Created 'git checkpoint' alias"
        echo "  Usage: git checkpoint -m \"Your commit message\""
    fi
    
    # Set up commit template if desired
    echo -e "${YELLOW}Use commit message template? (y/n)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cat > "$PROJECT_ROOT/.gitmessage" << 'EOF'
# Phase X.X: Brief description

# What changed:
# - 
# 

# Why:
# 

# Testing:
# 

# Phase status: [pending|in_progress|completed]
EOF
        git config --local commit.template .gitmessage
        echo -e "${GREEN}✓${NC} Commit template configured"
    fi
}

# Function to show usage instructions
show_usage() {
    echo -e "\n${BLUE}=== How to Use Git Hooks ===${NC}"
    echo ""
    echo -e "${CYAN}Automatic Features:${NC}"
    echo "  • Pre-commit: Validates and updates checkpoints before commit"
    echo "  • Post-commit: Logs completed tasks and shows progress"
    echo ""
    echo -e "${CYAN}Manual Commands:${NC}"
    echo "  • ${YELLOW}./scripts/auto-checkpoint.sh${NC} - Manually update checkpoints"
    echo "  • ${YELLOW}./scripts/verify-checkpoints.sh${NC} - Check consistency"
    echo "  • ${YELLOW}git checkpoint -m \"message\"${NC} - Commit with auto-checkpoint (if enabled)"
    echo ""
    echo -e "${CYAN}Workflow:${NC}"
    echo "  1. Make your changes"
    echo "  2. Stage files: ${YELLOW}git add .${NC}"
    echo "  3. Commit: ${YELLOW}git commit -m \"Phase 1.X: Description\"${NC}"
    echo "  4. Hooks will automatically:"
    echo "     - Update checkpoint files"
    echo "     - Verify consistency"
    echo "     - Log progress"
    echo "     - Create backups on phase completion"
}

# Main setup
main() {
    echo "Setting up Git hooks for: $PROJECT_ROOT"
    echo ""
    
    # Install hooks
    install_hook "pre-commit"
    install_hook "post-commit"
    
    # Make scripts executable
    make_scripts_executable
    
    # Test configuration
    if test_hooks; then
        echo -e "\n${GREEN}✓ Hooks installed successfully!${NC}"
    else
        echo -e "\n${RED}✗ Hook installation incomplete${NC}"
        exit 1
    fi
    
    # Optional git configuration
    setup_git_config
    
    # Show usage instructions
    show_usage
    
    echo -e "\n${GREEN}=== Setup Complete ===${NC}"
    echo -e "${CYAN}Your Git repository now has automatic checkpoint tracking!${NC}"
    echo ""
    echo -e "${YELLOW}Next step:${NC} Try making a commit to test the hooks"
    echo -e "Example: ${YELLOW}git commit -m \"Phase 1.2: Test hooks\"${NC}"
}

# Handle command line options
case "${1:-}" in
    --uninstall)
        echo -e "${RED}Uninstalling Git hooks...${NC}"
        rm -f "$PROJECT_ROOT/.git/hooks/pre-commit"
        rm -f "$PROJECT_ROOT/.git/hooks/post-commit"
        git config --local --unset alias.checkpoint 2>/dev/null || true
        git config --local --unset commit.template 2>/dev/null || true
        echo -e "${GREEN}✓ Hooks uninstalled${NC}"
        ;;
    --help)
        echo "Usage: $0 [--uninstall|--help]"
        echo ""
        echo "Options:"
        echo "  --uninstall  Remove Git hooks and configuration"
        echo "  --help       Show this help message"
        echo ""
        echo "Without options, installs Git hooks for checkpoint automation"
        ;;
    *)
        main
        ;;
esac