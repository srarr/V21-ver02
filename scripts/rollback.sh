#!/bin/bash
# Rollback to a previous snapshot

SNAPSHOT_ID="$1"

if [ -z "$SNAPSHOT_ID" ]; then
    echo "📸 Available snapshots:"
    echo ""
    if ls .snapshots/*.tar.gz >/dev/null 2>&1; then
        ls -lah .snapshots/*.tar.gz | while read -r perm links owner group size date time file; do
            SNAPSHOT_NAME=$(basename "$file" .tar.gz)
            echo "  $SNAPSHOT_NAME ($date $time, $size)"
            
            # Try to extract reason from metadata if possible
            if tar -tf "$file" | grep -q "metadata.json"; then
                REASON=$(tar -xzf "$file" -O "$SNAPSHOT_NAME/metadata.json" 2>/dev/null | jq -r '.reason' 2>/dev/null || echo "")
                if [ -n "$REASON" ] && [ "$REASON" != "null" ]; then
                    echo "    Reason: $REASON"
                fi
            fi
            echo ""
        done
    else
        echo "  No snapshots found"
        echo ""
        echo "Create a snapshot first:"
        echo "  ./scripts/create-snapshot.sh 'Reason for snapshot'"
    fi
    echo ""
    echo "Usage: $0 <snapshot-id>"
    echo "Example: $0 20240827-194500"
    exit 1
fi

SNAPSHOT_FILE=".snapshots/$SNAPSHOT_ID.tar.gz"

if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "❌ Snapshot not found: $SNAPSHOT_FILE"
    echo ""
    echo "Available snapshots:"
    ls -1 .snapshots/*.tar.gz 2>/dev/null | sed 's/.*\///; s/\.tar\.gz$//' | sed 's/^/  /'
    exit 1
fi

# Show snapshot info
echo "📸 Snapshot Information:"
if tar -tf "$SNAPSHOT_FILE" | grep -q "metadata.json" >/dev/null 2>&1; then
    echo "$(tar -xzf "$SNAPSHOT_FILE" -O "$SNAPSHOT_ID/metadata.json" 2>/dev/null | jq -r '
        "  Created: " + .created_at + 
        "\n  Reason: " + .reason +
        "\n  Git Hash: " + .git_hash +
        "\n  Git Branch: " + .git_branch +
        "\n  Project Phase: " + .project_phase
    ' 2>/dev/null || echo "  Snapshot metadata unavailable")"
else
    echo "  Basic snapshot (no metadata available)"
fi

echo ""
echo "⚠️  WARNING: This will replace your current code with the snapshot version!"
echo ""
echo "Current state will be backed up automatically before rollback."

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Rollback cancelled"
    exit 0
fi

# Create backup of current state before rollback
echo "📸 Creating backup of current state..."
BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
./scripts/create-snapshot.sh "Pre-rollback backup before restoring $SNAPSHOT_ID" >/dev/null 2>&1 || true
echo "✅ Current state backed up as $BACKUP_TIMESTAMP"

# Extract snapshot to temporary directory
echo "📦 Extracting snapshot..."
TMP_DIR="/tmp/heliox-rollback-$$"
mkdir -p "$TMP_DIR"
tar xzf "$SNAPSHOT_FILE" -C "$TMP_DIR"

if [ ! -d "$TMP_DIR/$SNAPSHOT_ID" ]; then
    echo "❌ Failed to extract snapshot"
    rm -rf "$TMP_DIR"
    exit 1
fi

SNAPSHOT_DIR="$TMP_DIR/$SNAPSHOT_ID"

# Rollback files
echo "🔄 Rolling back files..."

# Remove current directories that will be replaced
echo "  Cleaning current directories..."
[ -d "apps" ] && rm -rf apps
[ -d "contracts" ] && rm -rf contracts  
[ -d "tests" ] && rm -rf tests
[ -d "scripts" ] && rm -rf scripts
[ -d ".claude" ] && rm -rf .claude

# Restore from snapshot
echo "  Restoring from snapshot..."
[ -d "$SNAPSHOT_DIR/apps" ] && cp -r "$SNAPSHOT_DIR/apps" . || true
[ -d "$SNAPSHOT_DIR/contracts" ] && cp -r "$SNAPSHOT_DIR/contracts" . || true
[ -d "$SNAPSHOT_DIR/tests" ] && cp -r "$SNAPSHOT_DIR/tests" . || true
[ -d "$SNAPSHOT_DIR/scripts" ] && cp -r "$SNAPSHOT_DIR/scripts" . || true
[ -d "$SNAPSHOT_DIR/.claude" ] && cp -r "$SNAPSHOT_DIR/.claude" . || true

# Restore individual files
echo "  Restoring framework files..."
[ -f "$SNAPSHOT_DIR/Makefile" ] && cp "$SNAPSHOT_DIR/Makefile" . || true
cp "$SNAPSHOT_DIR"/*.md . 2>/dev/null || true
[ -f "$SNAPSHOT_DIR/.env.example" ] && cp "$SNAPSHOT_DIR/.env.example" . || true

# Handle .env carefully - restore as .env.snapshot, don't overwrite current .env
if [ -f "$SNAPSHOT_DIR/env-snapshot" ]; then
    cp "$SNAPSHOT_DIR/env-snapshot" .env.snapshot
    echo "  📝 Restored environment as .env.snapshot (review and copy to .env if needed)"
fi

# Restore package files
[ -f "$SNAPSHOT_DIR/package.json" ] && cp "$SNAPSHOT_DIR/package.json" . || true
[ -f "$SNAPSHOT_DIR/go.mod" ] && cp "$SNAPSHOT_DIR/go.mod" . || true
[ -f "$SNAPSHOT_DIR/Cargo.toml" ] && cp "$SNAPSHOT_DIR/Cargo.toml" . || true
[ -f "$SNAPSHOT_DIR/docker-compose.yml" ] && cp "$SNAPSHOT_DIR/docker-compose.yml" . || true

# Make scripts executable
if [ -d "scripts" ]; then
    echo "  Making scripts executable..."
    chmod +x scripts/*.sh 2>/dev/null || true
fi

if [ -d ".claude" ]; then
    chmod +x .claude/*.sh 2>/dev/null || true
fi

# Restore database schema if available
if [ -f "$SNAPSHOT_DIR/schema.sql" ] && [ -f .env ]; then
    echo "🗄️  Database schema available for restoration"
    echo "   To restore: psql \$POSTGRES_DSN < schema.sql"
    echo "   (Not automatically restored to avoid data loss)"
fi

# Update context with rollback info
if [ -f .claude/context.json ]; then
    jq --arg snapshot "$SNAPSHOT_ID" --arg backup "$BACKUP_TIMESTAMP" \
        '.lastRollback = {snapshot: $snapshot, backup: $backup, timestamp: now | todate}' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json || true
fi

# Clean up
rm -rf "$TMP_DIR"

echo ""
echo "✅ Rollback completed successfully!"
echo ""
echo "📊 Restoration Summary:"
echo "  ✅ Restored to snapshot: $SNAPSHOT_ID"  
echo "  ✅ Current state backed up as: $BACKUP_TIMESTAMP"
echo "  ✅ Scripts made executable"
echo ""

echo "🔍 Next steps:"
echo "  1. Review restored files"
echo "  2. Check .env.snapshot and update .env if needed"
echo "  3. Run './scripts/verify-setup.sh' to check environment"
echo "  4. Run './scripts/health-check.sh' to verify services"

if [ -f .claude/context.json ]; then
    RESTORED_PHASE=$(jq -r '.currentPhase' .claude/context.json 2>/dev/null || echo "unknown")
    RESTORED_TASK=$(jq -r '.activeTask' .claude/context.json 2>/dev/null || echo "unknown")
    echo ""
    echo "🎯 Restored to:"
    echo "  Phase: $RESTORED_PHASE"
    echo "  Task: $RESTORED_TASK"
fi

# Git status if in repo
if [ -d .git ]; then
    echo ""
    echo "📝 Git status after rollback:"
    git status --short || true
    echo ""
    echo "💡 Consider committing the rollback:"
    echo "   git add -A && git commit -m 'rollback: restored from snapshot $SNAPSHOT_ID'"
fi