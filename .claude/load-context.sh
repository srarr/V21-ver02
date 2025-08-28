#!/bin/bash
# Load saved context into environment

echo "🔄 Loading Claude context..."

# Check if context exists
if [ ! -f ".claude/context.json" ]; then
    echo "❌ No context found. Starting fresh."
    exit 1
fi

# Export key variables for shell environment
export HELIOX_PHASE=$(jq -r '.currentPhase' .claude/context.json)
export HELIOX_TASK=$(jq -r '.activeTask' .claude/context.json) 
export HELIOX_MILESTONE=$(jq -r '.currentMilestone' .claude/context.json)

# Show current state
echo "📊 Current State:"
echo "  Project: $(jq -r '.project' .claude/context.json)"
echo "  Milestone: $HELIOX_MILESTONE"
echo "  Phase: $HELIOX_PHASE"
echo "  Task: $HELIOX_TASK"
echo "  Last Updated: $(jq -r '.lastUpdated' .claude/context.json)"

# Show blockers
echo ""
echo "🚫 Active Blockers:"
jq -r '.blockers[]? | "  - \(.description) (ID: \(.id))"' .claude/context.json || echo "  No active blockers"

# Show working files
echo ""
echo "📁 Working Files:"
jq -r '.workingFiles[]? | "  - \(.)"' .claude/context.json || echo "  No working files tracked"

# Show framework progress
echo ""
echo "🚀 Framework Progress:"
jq -r '.frameworkProgress | to_entries[] | "  \(.key): \(.value)"' .claude/context.json

# Check service health if scripts exist
echo ""
echo "🔌 Service Status:"
SERVICES=("api" "postgres" "redis" "minio" "orchestrator" "frontend" "nats")

for service in "${SERVICES[@]}"; do
    if [ -f "./scripts/check-service.sh" ]; then
        if ./scripts/check-service.sh $service 2>/dev/null; then
            echo "  ✅ $service"
        else
            echo "  ❌ $service"
        fi
    else
        # Check if service is listed as running in context
        if jq -e --arg service "$service" '.systemState.servicesRunning[]? | select(. == $service)' .claude/context.json >/dev/null 2>&1; then
            echo "  ⚠️  $service (from context)"
        else
            echo "  ❌ $service (not running)"
        fi
    fi
done

# Check for recent snapshots
echo ""
echo "📸 Recent Snapshots:"
if [ -d ".claude/session-history" ]; then
    ls -lt .claude/session-history/*.tar.gz 2>/dev/null | head -3 | while read -r line; do
        echo "  $line"
    done
else
    echo "  No snapshots found"
fi

# Show next steps
echo ""
echo "🎯 Next Steps:"
if [ "$HELIOX_PHASE" = "Framework Setup" ]; then
    echo "  1. Complete framework files (scripts/, contracts/shared/, config files)"
    echo "  2. Run 'make setup' to initialize development environment"
    echo "  3. Start Phase 1.1 development"
else
    echo "  Check HANDOFF.md for current development status"
fi

# Show useful commands
echo ""
echo "🔧 Useful Commands:"
echo "  make help           - Show all available commands"
echo "  make verify         - Check environment setup"
echo "  cat HANDOFF.md      - View current project status"
echo "  cat ROADMAP.md      - View development roadmap"

echo ""
echo "✅ Context loaded. You can continue from where you left off."

# Show any critical warnings
LAST_UPDATE=$(jq -r '.lastUpdated' .claude/context.json)
if [ -n "$LAST_UPDATE" ] && [ "$LAST_UPDATE" != "null" ]; then
    # Simple age check (if date command supports ISO format)
    echo ""
    echo "ℹ️  Context last saved: $LAST_UPDATE"
fi