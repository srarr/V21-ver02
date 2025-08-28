#!/bin/bash
# Apply database migrations

echo "📊 Applying database migrations..."

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if .env exists and source it
if [ ! -f .env ]; then
    echo -e "${RED}❌ .env file not found${NC}"
    echo "Create .env from .env.example and configure POSTGRES_DSN"
    exit 1
fi

source .env

# Check if POSTGRES_DSN is set
if [ -z "$POSTGRES_DSN" ]; then
    echo -e "${RED}❌ POSTGRES_DSN not set in .env${NC}"
    echo "Configure your PostgreSQL connection string in .env"
    exit 1
fi

# Test database connection
echo -e "${BLUE}🔌 Testing database connection...${NC}"
if ! psql "$POSTGRES_DSN" -c 'SELECT 1' >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to database${NC}"
    echo "Connection string: $POSTGRES_DSN"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if PostgreSQL is running"
    echo "2. Verify connection string format"
    echo "3. Check credentials and permissions"
    echo "4. Ensure database exists"
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}"

# Create migrations table if it doesn't exist
echo -e "${BLUE}📝 Ensuring migrations table exists...${NC}"
psql "$POSTGRES_DSN" -c "
CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT NOW(),
    checksum VARCHAR(64)
);" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Migrations table ready${NC}"
else
    echo -e "${RED}❌ Failed to create migrations table${NC}"
    exit 1
fi

# Find all migration files
MIGRATION_DIR="contracts/schemas/sql/migrations"
if [ ! -d "$MIGRATION_DIR" ]; then
    echo -e "${RED}❌ Migration directory not found: $MIGRATION_DIR${NC}"
    exit 1
fi

# Get list of migration files
MIGRATIONS=($(ls "$MIGRATION_DIR"/*.sql 2>/dev/null | sort))

if [ ${#MIGRATIONS[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No migration files found in $MIGRATION_DIR${NC}"
    exit 0
fi

echo -e "${BLUE}📋 Found ${#MIGRATIONS[@]} migration file(s)${NC}"

# Apply each migration
APPLIED_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

for migration_file in "${MIGRATIONS[@]}"; do
    # Extract version from filename (e.g., 001_init.sql -> 001)
    FILENAME=$(basename "$migration_file")
    VERSION=$(echo "$FILENAME" | cut -d'_' -f1)
    
    echo ""
    echo -e "${BLUE}📄 Processing: $FILENAME${NC}"
    
    # Calculate checksum
    CHECKSUM=$(md5sum "$migration_file" | cut -d' ' -f1 2>/dev/null || shasum -a 256 "$migration_file" | cut -d' ' -f1)
    
    # Check if migration already applied
    EXISTING_CHECKSUM=$(psql "$POSTGRES_DSN" -t -c "SELECT checksum FROM schema_migrations WHERE version='$VERSION';" 2>/dev/null | tr -d ' \n')
    
    if [ -n "$EXISTING_CHECKSUM" ]; then
        if [ "$EXISTING_CHECKSUM" = "$CHECKSUM" ]; then
            echo -e "${GREEN}✅ Already applied (checksum matches)${NC}"
            ((SKIPPED_COUNT++))
            continue
        else
            echo -e "${YELLOW}⚠️  Migration exists but checksum differs${NC}"
            echo "   Existing: $EXISTING_CHECKSUM"  
            echo "   Current:  $CHECKSUM"
            echo "   This might indicate the migration file was modified"
            read -p "   Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}⏭️  Skipping $FILENAME${NC}"
                ((SKIPPED_COUNT++))
                continue
            fi
        fi
    fi
    
    # Apply migration
    echo -e "${BLUE}🔄 Applying migration...${NC}"
    
    # Start transaction and apply migration
    MIGRATION_OUTPUT=$(psql "$POSTGRES_DSN" -v ON_ERROR_STOP=1 -f "$migration_file" 2>&1)
    MIGRATION_STATUS=$?
    
    if [ $MIGRATION_STATUS -eq 0 ]; then
        # Record successful migration
        psql "$POSTGRES_DSN" -c "
            INSERT INTO schema_migrations (version, checksum) 
            VALUES ('$VERSION', '$CHECKSUM')
            ON CONFLICT (version) DO UPDATE 
            SET checksum = '$CHECKSUM', applied_at = NOW();" >/dev/null 2>&1
        
        echo -e "${GREEN}✅ Applied successfully${NC}"
        ((APPLIED_COUNT++))
        
        # Show a sample of what was created (tables, functions, etc.)
        echo -e "${BLUE}📊 Migration summary:${NC}"
        # Count tables, functions, etc. created by this migration
        TABLE_COUNT=$(echo "$MIGRATION_OUTPUT" | grep -c "CREATE TABLE" || echo "0")
        INDEX_COUNT=$(echo "$MIGRATION_OUTPUT" | grep -c "CREATE INDEX" || echo "0")
        FUNCTION_COUNT=$(echo "$MIGRATION_OUTPUT" | grep -c "CREATE FUNCTION" || echo "0")
        
        [ "$TABLE_COUNT" -gt 0 ] && echo "   Tables created: $TABLE_COUNT"
        [ "$INDEX_COUNT" -gt 0 ] && echo "   Indexes created: $INDEX_COUNT"  
        [ "$FUNCTION_COUNT" -gt 0 ] && echo "   Functions created: $FUNCTION_COUNT"
        
    else
        echo -e "${RED}❌ Migration failed${NC}"
        echo "Error output:"
        echo "$MIGRATION_OUTPUT" | sed 's/^/   /'
        ((FAILED_COUNT++))
        
        # Ask if we should continue with remaining migrations
        if [ ${#MIGRATIONS[@]} -gt 1 ]; then
            read -p "Continue with remaining migrations? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${RED}🛑 Migration process stopped${NC}"
                break
            fi
        fi
    fi
done

# Final summary
echo ""
echo -e "${BLUE}=== Migration Summary ===${NC}"
echo "Applied: $APPLIED_COUNT"
echo "Skipped: $SKIPPED_COUNT"  
echo "Failed: $FAILED_COUNT"

# Show current database state
echo ""
echo -e "${BLUE}📊 Current Database State:${NC}"
TABLE_LIST=$(psql "$POSTGRES_DSN" -t -c "SELECT schemaname||'.'||tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null | tr -d ' ')

if [ -n "$TABLE_LIST" ]; then
    echo "Tables:"
    echo "$TABLE_LIST" | sed 's/^/  /'
else
    echo "  No tables found"
fi

# Update context if available
if [ -f .claude/context.json ]; then
    jq --arg count "$APPLIED_COUNT" '.lastMigration = {applied: ($count | tonumber), timestamp: now | todate}' \
        .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

if [ $FAILED_COUNT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All migrations completed successfully!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  Some migrations failed${NC}"
    echo "Check the error messages above and fix the issues."
    exit 1
fi