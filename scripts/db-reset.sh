#!/bin/bash
# Reset database to clean state

echo "🔄 Resetting database..."

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
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}"

# Warning about destructive operation
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will permanently delete all data in the database!${NC}"
echo ""
echo "This will:"
echo "  - Drop all tables and data"
echo "  - Drop all functions and procedures"
echo "  - Drop all custom types"
echo "  - Reset the schema_migrations table"
echo ""

# Show what will be lost
echo -e "${BLUE}📊 Current database contents:${NC}"
TABLE_COUNT=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
FUNCTION_COUNT=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public';" 2>/dev/null | tr -d ' ')

echo "  Tables: ${TABLE_COUNT:-0}"
echo "  Functions/Procedures: ${FUNCTION_COUNT:-0}"

if [ "${TABLE_COUNT:-0}" -gt 0 ]; then
    echo ""
    echo "Tables that will be dropped:"
    psql "$POSTGRES_DSN" -t -c "SELECT '  ' || tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null
fi

echo ""
read -p "Are you sure you want to continue? Type 'yes' to confirm: " -r
if [ "$REPLY" != "yes" ]; then
    echo -e "${YELLOW}❌ Database reset cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔄 Starting database reset...${NC}"

# Create backup before reset (optional)
BACKUP_FILE="db_backup_before_reset_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${BLUE}💾 Creating backup before reset...${NC}"
if pg_dump "$POSTGRES_DSN" > "$BACKUP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  Backup failed, continuing anyway${NC}"
fi

# Drop all tables in public schema
echo -e "${BLUE}🗑️  Dropping all tables...${NC}"
DROP_TABLES_SQL="
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all tables
    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END \$\$;
"

if psql "$POSTGRES_DSN" -c "$DROP_TABLES_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ All tables dropped${NC}"
else
    echo -e "${RED}❌ Failed to drop some tables${NC}"
fi

# Drop all functions and procedures
echo -e "${BLUE}🗑️  Dropping all functions and procedures...${NC}"
DROP_FUNCTIONS_SQL="
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all functions and procedures
    FOR r IN (SELECT proname, oidvectortypes(proargtypes) as argtypes 
              FROM pg_proc 
              INNER JOIN pg_namespace ns ON (pg_proc.pronamespace = ns.oid)
              WHERE ns.nspname = 'public') 
    LOOP
        EXECUTE 'DROP FUNCTION IF EXISTS public.' || quote_ident(r.proname) || '(' || r.argtypes || ') CASCADE';
    END LOOP;
END \$\$;
"

if psql "$POSTGRES_DSN" -c "$DROP_FUNCTIONS_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ All functions dropped${NC}"
else
    echo -e "${YELLOW}⚠️  Some functions may remain${NC}"
fi

# Drop all custom types
echo -e "${BLUE}🗑️  Dropping all custom types...${NC}"
DROP_TYPES_SQL="
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all custom types
    FOR r IN (SELECT typname FROM pg_type 
              INNER JOIN pg_namespace ns ON (pg_type.typnamespace = ns.oid)
              WHERE ns.nspname = 'public' AND typtype = 'e') 
    LOOP
        EXECUTE 'DROP TYPE IF EXISTS public.' || quote_ident(r.typname) || ' CASCADE';
    END LOOP;
END \$\$;
"

if psql "$POSTGRES_DSN" -c "$DROP_TYPES_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ All custom types dropped${NC}"
else
    echo -e "${YELLOW}⚠️  Some types may remain${NC}"
fi

# Drop all sequences
echo -e "${BLUE}🗑️  Dropping all sequences...${NC}"
DROP_SEQUENCES_SQL="
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all sequences
    FOR r IN (SELECT sequencename FROM pg_sequences WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP SEQUENCE IF EXISTS public.' || quote_ident(r.sequencename) || ' CASCADE';
    END LOOP;
END \$\$;
"

if psql "$POSTGRES_DSN" -c "$DROP_SEQUENCES_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ All sequences dropped${NC}"
else
    echo -e "${YELLOW}⚠️  Some sequences may remain${NC}"
fi

# Drop all views
echo -e "${BLUE}🗑️  Dropping all views...${NC}"
DROP_VIEWS_SQL="
DO \$\$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all views
    FOR r IN (SELECT viewname FROM pg_views WHERE schemaname = 'public') 
    LOOP
        EXECUTE 'DROP VIEW IF EXISTS public.' || quote_ident(r.viewname) || ' CASCADE';
    END LOOP;
END \$\$;
"

if psql "$POSTGRES_DSN" -c "$DROP_VIEWS_SQL" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ All views dropped${NC}"
else
    echo -e "${YELLOW}⚠️  Some views may remain${NC}"
fi

# Verify database is clean
echo ""
echo -e "${BLUE}🔍 Verifying database is clean...${NC}"
REMAINING_TABLES=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
REMAINING_FUNCTIONS=$(psql "$POSTGRES_DSN" -t -c "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public';" 2>/dev/null | tr -d ' ')

echo "  Remaining tables: ${REMAINING_TABLES:-0}"
echo "  Remaining functions: ${REMAINING_FUNCTIONS:-0}"

if [ "${REMAINING_TABLES:-0}" -eq 0 ] && [ "${REMAINING_FUNCTIONS:-0}" -eq 0 ]; then
    echo -e "${GREEN}✅ Database successfully reset${NC}"
else
    echo -e "${YELLOW}⚠️  Some objects may still remain${NC}"
    
    # Show what's left
    if [ "${REMAINING_TABLES:-0}" -gt 0 ]; then
        echo ""
        echo "Remaining tables:"
        psql "$POSTGRES_DSN" -t -c "SELECT '  ' || tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null
    fi
fi

# Update context if available
if [ -f .claude/context.json ]; then
    jq '.lastDatabaseReset = now | todate' .claude/context.json > tmp.json && mv tmp.json .claude/context.json
fi

echo ""
echo -e "${GREEN}🎉 Database reset completed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Run 'make db-migrate' to apply migrations"
echo "  2. Run 'make db-seed' to add test data (if available)"
echo "  3. Verify with 'make health-check'"

if [ -f "$BACKUP_FILE" ]; then
    echo ""
    echo "💾 Backup available at: $BACKUP_FILE"
    echo "   (You can delete this file when no longer needed)"
fi