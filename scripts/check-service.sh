#!/bin/bash
# Check if a service is running

SERVICE=$1
TIMEOUT=${2:-5}  # Default 5 second timeout

if [ -z "$SERVICE" ]; then
    echo "Usage: $0 <service> [timeout_seconds]"
    echo "Available services: api, postgres, redis, minio, orchestrator, frontend, nats"
    exit 1
fi

case $SERVICE in
    api)
        # Check API Gateway
        BACKEND_ADDR=${BACKEND_HTTP_ADDR:-"http://localhost:8080"}
        timeout $TIMEOUT curl -f "$BACKEND_ADDR/health" >/dev/null 2>&1
        ;;
    postgres|postgresql|db)
        # Check PostgreSQL
        if [ -n "$POSTGRES_DSN" ]; then
            timeout $TIMEOUT psql "$POSTGRES_DSN" -c 'SELECT 1' >/dev/null 2>&1
        else
            # Try default connection
            timeout $TIMEOUT pg_isready -h localhost -p 5432 >/dev/null 2>&1
        fi
        ;;
    redis)
        # Check Redis
        if command -v redis-cli >/dev/null 2>&1; then
            timeout $TIMEOUT redis-cli ping >/dev/null 2>&1
        else
            false
        fi
        ;;
    minio)
        # Check MinIO
        MINIO_ENDPOINT=${MINIO_ENDPOINT:-"localhost:9000"}
        timeout $TIMEOUT curl -f "http://$MINIO_ENDPOINT/minio/health/live" >/dev/null 2>&1
        ;;
    orchestrator)
        # Check Orchestrator (typically internal, but might have health endpoint)
        timeout $TIMEOUT curl -f "http://localhost:3000/health" >/dev/null 2>&1
        ;;
    frontend|web)
        # Check Frontend dev server
        timeout $TIMEOUT curl -f "http://localhost:5173" >/dev/null 2>&1
        ;;
    nats)
        # Check NATS server
        if command -v nats >/dev/null 2>&1; then
            timeout $TIMEOUT nats server ping >/dev/null 2>&1
        else
            # Fallback to HTTP monitoring endpoint
            timeout $TIMEOUT curl -f "http://localhost:8222/varz" >/dev/null 2>&1
        fi
        ;;
    docker)
        # Check Docker daemon
        timeout $TIMEOUT docker ps >/dev/null 2>&1
        ;;
    *)
        echo "Unknown service: $SERVICE" >&2
        echo "Available services: api, postgres, redis, minio, orchestrator, frontend, nats, docker" >&2
        exit 1
        ;;
esac

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    exit 0
else
    # Provide helpful error messages
    case $SERVICE in
        api)
            echo "API Gateway not responding at $BACKEND_ADDR" >&2
            echo "Try: make dev-api" >&2
            ;;
        postgres)
            echo "PostgreSQL not accessible" >&2
            echo "Try: Check if PostgreSQL is installed and running" >&2
            ;;
        redis)
            echo "Redis not responding" >&2
            echo "Try: redis-server (if installed)" >&2
            ;;
        minio)
            echo "MinIO not responding at http://$MINIO_ENDPOINT" >&2
            echo "Try: Install and start MinIO server" >&2
            ;;
        frontend)
            echo "Frontend dev server not responding" >&2
            echo "Try: make dev-web" >&2
            ;;
        nats)
            echo "NATS server not responding" >&2
            echo "Try: Install and start NATS server" >&2
            ;;
    esac
    exit 1
fi