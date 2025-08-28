#!/usr/bin/env bash

# Heliox ATLAS v21 - Setup convenient aliases for WSL

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Setting up Heliox aliases...${NC}"

# Project directory
PROJECT_DIR="/mnt/c/New Claude Code/V21 Ver01"

# Aliases to add
ALIASES="
# Heliox ATLAS v21 aliases
alias heliox='cd \"$PROJECT_DIR\" && ./start-heliox.sh'
alias heliox-dev='cd \"$PROJECT_DIR\" && make dev'
alias heliox-test='cd \"$PROJECT_DIR\" && make test'
alias heliox-help='cd \"$PROJECT_DIR\" && make help'
alias heliox-db='cd \"$PROJECT_DIR\" && make db-up'
alias heliox-status='cd \"$PROJECT_DIR\" && git status'
alias heliox-claude='cd \"$PROJECT_DIR\" && code .'
"

# Check if aliases already exist
if grep -q "# Heliox ATLAS v21 aliases" ~/.bashrc 2>/dev/null; then
    echo -e "${YELLOW}Heliox aliases already exist in ~/.bashrc${NC}"
    echo "Updating them..."
    
    # Remove old aliases
    sed -i '/# Heliox ATLAS v21 aliases/,/^$/d' ~/.bashrc
fi

# Add aliases to .bashrc
echo "$ALIASES" >> ~/.bashrc

echo -e "${GREEN}✓ Aliases added to ~/.bashrc${NC}"
echo
echo "Available commands:"
echo -e "  ${CYAN}heliox${NC}        - Start Heliox welcome screen"
echo -e "  ${CYAN}heliox-dev${NC}    - Start development servers"
echo -e "  ${CYAN}heliox-test${NC}   - Run tests"
echo -e "  ${CYAN}heliox-help${NC}   - Show all make commands"
echo -e "  ${CYAN}heliox-db${NC}     - Start Supabase database"
echo -e "  ${CYAN}heliox-status${NC} - Show git status"
echo -e "  ${CYAN}heliox-claude${NC} - Open in VS Code"
echo
echo -e "${YELLOW}To activate now, run:${NC}"
echo -e "${GREEN}source ~/.bashrc${NC}"
echo
echo -e "${YELLOW}Or just type:${NC}"
echo -e "${GREEN}. ~/.bashrc${NC}"