#!/bin/bash
# Update project state after completing a task

MESSAGE="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

if [ -z "$MESSAGE" ]; then
    echo "Usage: $0 'Description of completed task'"
    echo ""
    echo "Example: $0 'Completed API endpoints for /v1/runs'"
    exit 1
fi

echo "📝 Updating project state..."

# Update completed.txt
echo "[$DATE] [${TIMESTAMP#* }] [$(jq -r '.currentPhase' .claude/context.json 2>/dev/null || echo 'Unknown')] $MESSAGE" >> .claude/completed.txt

# Update context.json with last completed task and timestamp
if [ -f .claude/context.json ]; then
    jq --arg msg "$MESSAGE" --arg ts "$(date -Iseconds)" \
        '.lastUpdated = $ts | .lastCompletedTask = $msg' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json
else
    echo "Warning: .claude/context.json not found"
fi

echo "✅ State updated: $MESSAGE"

# Show current progress
if [ -f .claude/context.json ]; then
    CURRENT_PHASE=$(jq -r '.currentPhase' .claude/context.json)
    CURRENT_TASK=$(jq -r '.activeTask' .claude/context.json)
    echo "📊 Current phase: $CURRENT_PHASE"
    echo "🎯 Active task: $CURRENT_TASK"
fi

# Show recent completed tasks
echo ""
echo "📋 Recent completions:"
tail -3 .claude/completed.txt | while IFS= read -r line; do
    echo "  $line"
done

# Auto-commit if in git repo
if [ -d .git ]; then
    echo ""
    echo "📝 Auto-committing state update..."
    git add .claude/ >/dev/null 2>&1 || true
    git commit -m "state: $MESSAGE" >/dev/null 2>&1 || true
    echo "✅ Changes committed to git"
fi

echo ""
echo "💡 Tip: Run './scripts/health-check.sh' to see overall project status"