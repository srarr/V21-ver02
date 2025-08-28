#!/usr/bin/env bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}${BLUE}Heliox ATLAS v21 - WSL Alias Setup${NC}"
echo -e "${BLUE}===================================${NC}"
echo

# Detect shell
SHELL_RC=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    echo -e "${GREEN}Detected: ZSH${NC}"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    echo -e "${GREEN}Detected: Bash${NC}"
else
    echo -e "${YELLOW}Warning: Unknown shell. Defaulting to .bashrc${NC}"
    SHELL_RC="$HOME/.bashrc"
fi

# Project directory (adjust if needed)
PROJECT_DIR="/mnt/c/New Claude Code/V21 Ver01"

# Check if project exists
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}Warning: Project directory not found at:${NC}"
    echo "  $PROJECT_DIR"
    echo
    read -p "Enter correct project path: " PROJECT_DIR
fi

echo
echo -e "${BLUE}Adding aliases to: $SHELL_RC${NC}"
echo

# Backup existing RC file
cp "$SHELL_RC" "$SHELL_RC.backup.$(date +%Y%m%d%H%M%S)"
echo -e "${GREEN}✓ Created backup of $SHELL_RC${NC}"

# Create alias block
cat >> "$SHELL_RC" << 'EOF'

# ============================================
# Heliox ATLAS v21 - Trading Platform Aliases
# ============================================

# Quick navigation to project
alias heliox='cd "/mnt/c/New Claude Code/V21 Ver01"'
alias atlas='cd "/mnt/c/New Claude Code/V21 Ver01"'

# Start project with status display
alias heliox-start='cd "/mnt/c/New Claude Code/V21 Ver01" && ./start-heliox.sh'

# Quick development commands
alias heliox-dev='cd "/mnt/c/New Claude Code/V21 Ver01" && make dev'
alias heliox-db='cd "/mnt/c/New Claude Code/V21 Ver01" && make db-up'
alias heliox-test='cd "/mnt/c/New Claude Code/V21 Ver01" && make test'

# Open Claude Code with reminder
heliox-claude() {
    cd "/mnt/c/New Claude Code/V21 Ver01"
    echo "📁 Opening Claude Code in: $(pwd)"
    echo "📝 Remember to load:"
    echo "   1. ROADMAP.md"
    echo "   2. CONTINUITY.md"
    echo "   3. CLAUDE.md"
    echo ""
    
    if command -v claude &> /dev/null; then
        claude .
    elif command -v code &> /dev/null; then
        code .
    else
        echo "⚠️  Claude Code command not found"
        echo "   Please open manually"
    fi
}

# Quick status check
heliox-status() {
    cd "/mnt/c/New Claude Code/V21 Ver01"
    echo "🚀 Heliox ATLAS v21 Status"
    echo "=========================="
    echo "📁 Location: $(pwd)"
    
    if [ -d .git ]; then
        echo "🔧 Git: $(git branch --show-current 2>/dev/null || echo 'main')"
        CHANGES=$(git status --porcelain 2>/dev/null | wc -l)
        if [ "$CHANGES" -gt 0 ]; then
            echo "   ⚠️  $CHANGES uncommitted changes"
        else
            echo "   ✓ Working tree clean"
        fi
    fi
    
    if command -v supabase &> /dev/null && supabase status 2>/dev/null | grep -q "API URL"; then
        echo "🐘 Supabase: Running"
    else
        echo "🐘 Supabase: Not running"
    fi
    
    echo ""
    echo "Quick commands:"
    echo "  heliox-dev    - Start development"
    echo "  heliox-db     - Start database"
    echo "  heliox-claude - Open Claude Code"
}

# Help command
heliox-help() {
    echo "🚀 Heliox ATLAS v21 - Available Commands"
    echo "========================================"
    echo "  heliox         - Go to project directory"
    echo "  heliox-start   - Run startup script with status"
    echo "  heliox-dev     - Start all dev services"
    echo "  heliox-db      - Start Supabase database"
    echo "  heliox-test    - Run all tests"
    echo "  heliox-claude  - Open Claude Code with reminders"
    echo "  heliox-status  - Show project status"
    echo "  heliox-help    - Show this help"
}

# Auto-run on new terminal (optional - uncomment if desired)
# heliox-status

EOF

echo -e "${GREEN}✓ Aliases added to $SHELL_RC${NC}"
echo

# Make start script executable
chmod +x "$PROJECT_DIR/start-heliox.sh" 2>/dev/null
echo -e "${GREEN}✓ Made start-heliox.sh executable${NC}"

echo
echo -e "${BOLD}${GREEN}Setup Complete!${NC}"
echo
echo "To activate the aliases, run:"
echo -e "  ${BLUE}source $SHELL_RC${NC}"
echo
echo "Available commands:"
echo -e "  ${BLUE}heliox${NC}        - Navigate to project"
echo -e "  ${BLUE}heliox-start${NC}  - Show project status"
echo -e "  ${BLUE}heliox-claude${NC} - Open Claude Code"
echo -e "  ${BLUE}heliox-help${NC}   - See all commands"
echo
echo -e "${YELLOW}Tip: Add 'heliox-status' to your shell RC file${NC}"
echo -e "${YELLOW}     to see project status on terminal startup${NC}"