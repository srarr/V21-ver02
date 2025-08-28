#!/usr/bin/env bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print colored headers
print_header() {
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${CYAN}🚀 HELIOX ATLAS v21 Trading Platform${NC}  ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo
}

# Function to print section
print_section() {
    echo -e "${BOLD}${MAGENTA}▸ $1${NC}"
}

# Function to print status
print_status() {
    echo -e "  ${GREEN}✓${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

# Function to print info
print_info() {
    echo -e "  ${CYAN}ℹ${NC} $1"
}

# Main script
clear
print_header

# Change to project directory
cd "/mnt/c/New Claude Code/V21 Ver01" || exit 1

print_section "Project Status"
print_status "Location: $(pwd)"

# Check git status
if [ -d .git ]; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    print_status "Git Branch: $BRANCH"
    
    # Count changes
    CHANGED=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$CHANGED" -gt 0 ]; then
        print_warning "$CHANGED uncommitted changes"
    else
        print_status "Working tree clean"
    fi
else
    print_info "Not a git repository"
fi

echo

print_section "Environment Check"

# Check key tools
if command -v go &> /dev/null; then
    print_status "Go $(go version | cut -d' ' -f3)"
else
    print_warning "Go not installed"
fi

if command -v node &> /dev/null; then
    print_status "Node.js $(node --version)"
else
    print_warning "Node.js not installed"
fi

if command -v supabase &> /dev/null; then
    print_status "Supabase CLI installed"
    
    # Check if Supabase is running
    if supabase status 2>/dev/null | grep -q "API URL"; then
        print_status "Supabase is running"
    else
        print_info "Supabase not running (run: make db-up)"
    fi
else
    print_warning "Supabase CLI not installed"
fi

echo

print_section "Quick Commands"
echo -e "  ${CYAN}make dev${NC}      - Start all services"
echo -e "  ${CYAN}make db-up${NC}    - Start Supabase"
echo -e "  ${CYAN}make test${NC}     - Run tests"
echo -e "  ${CYAN}make help${NC}     - See all commands"

echo

print_section "Claude Code Context"
echo -e "  ${GREEN}Load these files in Claude:${NC}"
echo "  1. ROADMAP.md    - Development phases"
echo "  2. CONTINUITY.md - Current progress"
echo "  3. CLAUDE.md     - Architecture guide"

echo
echo -e "${BOLD}${GREEN}Ready to continue development!${NC}"
echo -e "${CYAN}Current Phase:${NC} Ready for Phase 1.2 (API Implementation)"
echo

# Optional: Open Claude Code with context
read -p "Open Claude Code now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Opening Claude Code...${NC}"
    echo -e "${YELLOW}Remember to load: ROADMAP.md, CONTINUITY.md, and CLAUDE.md${NC}"
    
    # Try to open Claude Code (adjust command as needed)
    if command -v claude &> /dev/null; then
        claude .
    elif command -v code &> /dev/null; then
        code .
    else
        echo -e "${YELLOW}Please open Claude Code manually${NC}"
    fi
fi