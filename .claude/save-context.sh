#!/bin/bash
# Save current context

echo "💾 Saving Claude context..."

# Update timestamp
jq '.lastUpdated = now | todate' .claude/context.json > tmp.json && mv tmp.json .claude/context.json

# Save git state if git repo exists
if [ -d .git ]; then
    echo "📝 Saving git state..."
    git log --oneline -10 > .claude/git-state.txt 2>/dev/null || echo "No git history yet" > .claude/git-state.txt
    git status > .claude/git-status.txt 2>/dev/null || echo "Not a git repository" >> .claude/git-status.txt
fi

# Check running services and update context
echo "🔌 Checking services..."
SERVICES=("api" "postgres" "redis" "minio" "orchestrator" "frontend" "nats")
RUNNING_SERVICES=()

for service in "${SERVICES[@]}"; do
    if ./scripts/check-service.sh $service 2>/dev/null; then
        RUNNING_SERVICES+=("\"$service\"")
    fi
done

# Update running services in context (only if check-service.sh exists)
if [ -f "./scripts/check-service.sh" ]; then
    SERVICES_JSON=$(IFS=,; echo "[${RUNNING_SERVICES[*]}]")
    jq ".systemState.servicesRunning = $SERVICES_JSON" .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

# Update framework progress
FRAMEWORK_STATUS=$(jq -r '.frameworkProgress' .claude/context.json)
jq '.systemState.lastHealthCheck = now | todate' .claude/context.json > tmp.json && mv tmp.json .claude/context.json

# Create session snapshot
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_DIR=".claude/session-history"
SNAPSHOT_FILE="$SNAPSHOT_DIR/$TIMESTAMP.tar.gz"

mkdir -p $SNAPSHOT_DIR

# Create temporary directory for snapshot
TMP_DIR="/tmp/claude-snapshot-$$"
mkdir -p $TMP_DIR

# Copy key files for snapshot
cp .claude/context.json $TMP_DIR/ 2>/dev/null || true
cp .claude/completed.txt $TMP_DIR/ 2>/dev/null || true
cp .claude/dependencies.txt $TMP_DIR/ 2>/dev/null || true
cp .claude/decisions-log.json $TMP_DIR/ 2>/dev/null || true
cp .claude/errors-log.json $TMP_DIR/ 2>/dev/null || true

# Add current working files
if [ -f "HANDOFF.md" ]; then cp HANDOFF.md $TMP_DIR/; fi
if [ -f ".env" ]; then cp .env $TMP_DIR/env-snapshot; fi

# Create the snapshot
tar czf $SNAPSHOT_FILE -C $TMP_DIR . 2>/dev/null || echo "Warning: Could not create snapshot archive"

# Clean up
rm -rf $TMP_DIR

echo "✅ Context saved!"
echo "📊 Current phase: $(jq -r '.currentPhase' .claude/context.json)"
echo "📝 Active task: $(jq -r '.activeTask' .claude/context.json)"
echo "💾 Snapshot: $SNAPSHOT_FILE"

# Show summary
echo ""
echo "📈 Progress Summary:"
jq -r '.frameworkProgress | to_entries[] | "  \(.key): \(.value)"' .claude/context.json

if [ ${#RUNNING_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo "🟢 Running services: ${RUNNING_SERVICES[*]//\"/}"
else
    echo ""
    echo "⚠️  No services currently running"
fi