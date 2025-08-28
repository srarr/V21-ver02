#!/usr/bin/env bash

echo "🔍 Checking prerequisites for Heliox ATLAS v21..."
echo "================================================"
echo ""

# Track if all required tools are present
ALL_GOOD=true

# Check Docker
if command -v docker >/dev/null 2>&1; then
  echo "✅ Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
  echo "⚠️  Docker: Not found (needed for Supabase)"
  echo "   Install from: https://docker.com/get-started"
  ALL_GOOD=false
fi

# Check Supabase CLI
if command -v supabase >/dev/null 2>&1; then
  echo "✅ Supabase CLI: $(supabase --version | cut -d' ' -f3)"
else
  echo "⚠️  Supabase CLI: Not found"
  echo "   Install: npm install -g supabase"
  echo "   or visit: https://supabase.com/docs/guides/cli"
  ALL_GOOD=false
fi

# Check Go
if command -v go >/dev/null 2>&1; then
  echo "✅ Go: $(go version | cut -d' ' -f3)"
else
  echo "⚠️  Go: Not found (needed for API)"
  echo "   Install Go 1.22+ from: https://go.dev/download"
  ALL_GOOD=false
fi

# Check Node.js
if command -v node >/dev/null 2>&1; then
  echo "✅ Node.js: $(node --version)"
else
  echo "⚠️  Node.js: Not found (needed for Web UI)"
  echo "   Install Node 20+ from: https://nodejs.org"
  ALL_GOOD=false
fi

# Check Python (for Orchestrator)
if command -v python3 >/dev/null 2>&1; then
  echo "✅ Python: $(python3 --version | cut -d' ' -f2)"
else
  echo "⚠️  Python: Not found (needed for Orchestrator)"
  echo "   Install Python 3.11+ from: https://python.org"
fi

# Check npm
if command -v npm >/dev/null 2>&1; then
  echo "✅ npm: $(npm --version)"
else
  echo "⚠️  npm: Not found"
  echo "   Usually comes with Node.js"
fi

echo ""
echo "=================================="

# Check environment file
if [ -f ".env" ]; then
  echo "✅ .env file exists"
else
  echo "⚠️  .env file not found"
  echo "   Run: cp .env.example .env"
fi

# Check if Docker is running
if command -v docker >/dev/null 2>&1; then
  if docker ps >/dev/null 2>&1; then
    echo "✅ Docker is running"
  else
    echo "⚠️  Docker is not running"
    echo "   Please start Docker Desktop"
  fi
fi

echo ""

# Final status
if [ "$ALL_GOOD" = true ]; then
  echo "✅ All required prerequisites are installed!"
  echo "   You can run: make dev"
  echo "   or: ./scripts/quick-start.sh"
else
  echo "📝 Note: Missing tools won't completely block development"
  echo "   You can start with partial setup and add tools later"
  echo "   For example, you can work on the Web UI without Go installed"
fi

echo ""
echo "💡 Tips:"
echo "   - Use 'make setup' to install dependencies"
echo "   - Use 'make dev' to start all services"
echo "   - Use 'make help' to see all available commands"
echo ""