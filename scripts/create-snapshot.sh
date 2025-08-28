#!/bin/bash
# Create a full project snapshot for rollback

REASON="$1"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_DIR=".snapshots/$TIMESTAMP"

if [ -z "$REASON" ]; then
    REASON="Manual snapshot"
fi

echo "📸 Creating snapshot $TIMESTAMP..."
echo "Reason: $REASON"

# Create snapshots directory
mkdir -p .snapshots

# Create temporary snapshot directory
mkdir -p $SNAPSHOT_DIR

echo "📦 Copying project files..."

# Copy application directories (if they exist)
[ -d "apps" ] && cp -r apps $SNAPSHOT_DIR/ 2>/dev/null || true
[ -d "contracts" ] && cp -r contracts $SNAPSHOT_DIR/ 2>/dev/null || true
[ -d "tests" ] && cp -r tests $SNAPSHOT_DIR/ 2>/dev/null || true
[ -d "scripts" ] && cp -r scripts $SNAPSHOT_DIR/ 2>/dev/null || true

# Copy framework files
cp -r .claude $SNAPSHOT_DIR/ 2>/dev/null || true
cp *.md $SNAPSHOT_DIR/ 2>/dev/null || true
cp Makefile $SNAPSHOT_DIR/ 2>/dev/null || true
[ -f ".env" ] && cp .env $SNAPSHOT_DIR/env-snapshot 2>/dev/null || true
[ -f ".env.example" ] && cp .env.example $SNAPSHOT_DIR/ 2>/dev/null || true

# Copy package files
[ -f "package.json" ] && cp package.json $SNAPSHOT_DIR/ 2>/dev/null || true
[ -f "go.mod" ] && cp go.mod $SNAPSHOT_DIR/ 2>/dev/null || true
[ -f "Cargo.toml" ] && cp Cargo.toml $SNAPSHOT_DIR/ 2>/dev/null || true
[ -f "docker-compose.yml" ] && cp docker-compose.yml $SNAPSHOT_DIR/ 2>/dev/null || true

echo "📝 Saving git state..."
if [ -d .git ]; then
    git log --oneline -20 > $SNAPSHOT_DIR/git-log.txt 2>/dev/null || true
    git status > $SNAPSHOT_DIR/git-status.txt 2>/dev/null || true
    git diff > $SNAPSHOT_DIR/git-diff.txt 2>/dev/null || true
    git branch -v > $SNAPSHOT_DIR/git-branches.txt 2>/dev/null || true
    
    # Save current commit hash
    git rev-parse HEAD > $SNAPSHOT_DIR/git-commit-hash.txt 2>/dev/null || true
else
    echo "No git repository" > $SNAPSHOT_DIR/git-log.txt
fi

echo "💾 Saving database schema..."
if [ -f .env ]; then
    source .env
    if [ -n "$POSTGRES_DSN" ]; then
        pg_dump "$POSTGRES_DSN" --schema-only > $SNAPSHOT_DIR/schema.sql 2>/dev/null || echo "-- Database not accessible" > $SNAPSHOT_DIR/schema.sql
        # Also try to save some sample data
        pg_dump "$POSTGRES_DSN" --data-only --table=projects --table=docs > $SNAPSHOT_DIR/sample-data.sql 2>/dev/null || true
    fi
fi

echo "🔍 Capturing system state..."
# Save system information
cat > $SNAPSHOT_DIR/system-info.txt << EOF
Snapshot created: $(date)
Hostname: $(hostname)
User: $(whoami)
OS: $(uname -a)
Go version: $(go version 2>/dev/null || echo "Not installed")
Node version: $(node -v 2>/dev/null || echo "Not installed")
PostgreSQL: $(psql --version 2>/dev/null || echo "Not installed")
Working directory: $(pwd)
Disk usage: $(df -h . | tail -1)
EOF

# Save current context
if [ -f .claude/context.json ]; then
    jq . .claude/context.json > $SNAPSHOT_DIR/context-snapshot.json 2>/dev/null || cp .claude/context.json $SNAPSHOT_DIR/context-snapshot.json
fi

# Create metadata
cat > $SNAPSHOT_DIR/metadata.json << EOF
{
    "snapshot_id": "$TIMESTAMP",
    "created_at": "$(date -Iseconds)",
    "reason": "$REASON",
    "git_hash": "$(git rev-parse HEAD 2>/dev/null || echo 'no-git')",
    "git_branch": "$(git branch --show-current 2>/dev/null || echo 'no-git')",
    "created_by": "$USER",
    "hostname": "$(hostname)",
    "project_phase": "$(jq -r '.currentPhase' .claude/context.json 2>/dev/null || echo 'unknown')",
    "files_count": $(find $SNAPSHOT_DIR -type f | wc -l),
    "size_bytes": $(du -sb $SNAPSHOT_DIR | cut -f1)
}
EOF

echo "🗜️ Compressing snapshot..."
# Compress the snapshot
tar czf .snapshots/$TIMESTAMP.tar.gz -C .snapshots $TIMESTAMP

# Remove temporary directory
rm -rf $SNAPSHOT_DIR

# Get compressed size
COMPRESSED_SIZE=$(du -sh .snapshots/$TIMESTAMP.tar.gz | cut -f1)

echo "✅ Snapshot created successfully!"
echo "📁 Location: .snapshots/$TIMESTAMP.tar.gz"
echo "📏 Size: $COMPRESSED_SIZE"
echo ""

# Show available snapshots
echo "📸 Available snapshots:"
ls -lah .snapshots/*.tar.gz 2>/dev/null | tail -5 | while read -r perm links owner group size date time file; do
    echo "  $date $time $size $(basename $file)"
done

# Update context with snapshot info
if [ -f .claude/context.json ]; then
    jq --arg snapshot "$TIMESTAMP" --arg reason "$REASON" \
        '.lastSnapshot = {id: $snapshot, reason: $reason, created_at: now | todate}' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

echo ""
echo "💡 To restore this snapshot later:"
echo "   ./scripts/rollback.sh $TIMESTAMP"

# Auto-cleanup old snapshots (keep last 10)
SNAPSHOT_COUNT=$(ls -1 .snapshots/*.tar.gz 2>/dev/null | wc -l)
if [ "$SNAPSHOT_COUNT" -gt 10 ]; then
    echo ""
    echo "🧹 Cleaning up old snapshots (keeping 10 most recent)..."
    ls -1t .snapshots/*.tar.gz | tail -n +11 | xargs rm -f
    echo "✅ Cleanup complete"
fi