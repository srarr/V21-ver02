#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Heliox ATLAS v21 - Quick Start"
echo "=================================="

# Setup .env if not exists
if [ ! -f .env ]; then
  echo "📝 Creating .env from .env.example..."
  cp .env.example .env
fi

# Check for Supabase CLI
if ! command -v supabase &> /dev/null; then
  echo "⚠️  Supabase CLI not found. Please install it:"
  echo "   npm install -g supabase"
  echo "   or visit: https://supabase.com/docs/guides/cli"
  echo ""
  echo "Continuing without database..."
else
  # Initialize Supabase if needed
  if [ ! -d "supabase" ]; then
    echo "📦 Initializing Supabase..."
    supabase init
  fi

  # Start Supabase
  echo "🐘 Starting Supabase..."
  supabase start || echo "⚠️  Supabase start failed. Check Docker is running."
  
  echo "📝 Supabase started. Update .env with SUPABASE_ANON_KEY from above output if needed."
fi

# Check for Go
if ! command -v go &> /dev/null; then
  echo "⚠️  Go not found. API will not start."
  echo "   Install from: https://go.dev/download"
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
  echo "⚠️  Node.js not found. Web UI will not start."
  echo "   Install from: https://nodejs.org"
fi

echo ""
echo "🔧 Starting available services..."
echo ""

# Start API (if Go is available)
if command -v go &> /dev/null && [ -d "apps/api" ]; then
  echo "🚀 Starting API on http://localhost:8080..."
  (cd apps/api && go run ./cmd/api 2>/dev/null || echo "❌ API failed to start") &
  API_PID=$!
else
  echo "⏭️  Skipping API (Go not found or apps/api missing)"
  API_PID=""
fi

# Start Web (if Node is available)
if command -v node &> /dev/null && [ -d "apps/web" ]; then
  echo "🖥️  Starting Web on http://localhost:5173..."
  (cd apps/web && npm run dev 2>/dev/null || echo "❌ Web failed to start") &
  WEB_PID=$!
else
  echo "⏭️  Skipping Web (Node not found or apps/web missing)"
  WEB_PID=""
fi

echo ""
echo "✅ Services starting..."
echo "   Web: http://localhost:5173"
echo "   API: http://localhost:8080"

# Only show Supabase Studio if Supabase is running
if command -v supabase &> /dev/null && supabase status 2>/dev/null | grep -q "API URL"; then
  echo "   Supabase Studio: http://localhost:54323"
fi

echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Function to cleanup on exit
cleanup() {
  echo ""
  echo "🛑 Stopping services..."
  
  # Kill API and Web processes
  if [ -n "$API_PID" ]; then
    kill $API_PID 2>/dev/null || true
  fi
  if [ -n "$WEB_PID" ]; then
    kill $WEB_PID 2>/dev/null || true
  fi
  
  # Kill any child processes
  kill $(jobs -p) 2>/dev/null || true
  
  # Stop Supabase if it's running
  if command -v supabase &> /dev/null; then
    supabase stop 2>/dev/null || true
  fi
  
  echo "👋 Goodbye!"
  exit 0
}

# Set up cleanup on Ctrl+C
trap cleanup INT TERM

# Wait for processes
wait