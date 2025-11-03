#!/usr/bin/env bash
#
# AspireCloud Initialization Script
# Runs necessary initialization steps inside the AspireCloud container
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTAINER_NAME="cloudfest-aspirecloud"

echo -e "${BLUE}Initializing AspireCloud...${NC}"

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}ERROR: AspireCloud container is not running${NC}"
    exit 1
fi

# Wait for AspireCloud to be ready
echo -e "${YELLOW}Waiting for AspireCloud container to be ready...${NC}"
timeout 60 bash -c "until docker exec ${CONTAINER_NAME} php -v >/dev/null 2>&1; do sleep 2; done" || {
    echo -e "${RED}AspireCloud container failed to initialize${NC}"
    exit 1
}

# Check if APP_KEY is set
echo -e "${YELLOW}Verifying APP_KEY is set...${NC}"
APP_KEY=$(docker exec ${CONTAINER_NAME} printenv APP_KEY 2>/dev/null || echo "")
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then
    echo -e "${RED}ERROR: APP_KEY is not set!${NC}"
    echo -e "${YELLOW}Recreating container to pick up environment changes...${NC}"
    docker-compose up -d ${CONTAINER_NAME}
    sleep 5
    APP_KEY=$(docker exec ${CONTAINER_NAME} printenv APP_KEY 2>/dev/null || echo "")
    if [ -z "$APP_KEY" ]; then
        echo -e "${RED}FATAL: APP_KEY still not set. Please check docker-compose.yml${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ APP_KEY is configured${NC}"

# Clear and optimize cache
echo -e "${YELLOW}Clearing Laravel cache...${NC}"
docker exec ${CONTAINER_NAME} php artisan optimize:clear >/dev/null 2>&1 || {
    echo -e "${YELLOW}Warning: Could not clear cache (this is normal on first run)${NC}"
}

# Run database migrations (won't reset data, just applies pending migrations)
echo -e "${YELLOW}Running database migrations...${NC}"
docker exec ${CONTAINER_NAME} php artisan migrate --force --no-interaction || {
    echo -e "${YELLOW}Warning: Migrations may have already been applied${NC}"
}

# Verify database connectivity
echo -e "${YELLOW}Verifying database connectivity...${NC}"
if docker exec ${CONTAINER_NAME} php artisan migrate:status >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection is working${NC}"
else
    echo -e "${RED}WARNING: Could not verify database connection${NC}"
fi

# Test API endpoint
echo -e "${YELLOW}Testing AspireCloud API...${NC}"
if docker exec ${CONTAINER_NAME} curl -sf http://localhost:80/ >/dev/null 2>&1; then
    echo -e "${GREEN}✓ AspireCloud API is responding${NC}"
else
    echo -e "${RED}WARNING: AspireCloud API is not responding correctly${NC}"
    echo -e "${YELLOW}You may need to restart the container: docker restart ${CONTAINER_NAME}${NC}"
fi

echo -e "${GREEN}AspireCloud initialization complete!${NC}"
