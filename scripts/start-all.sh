#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}CloudFest Hackathon - Starting Development Environment${NC}"
echo "========================================================="
echo ""

# Check if SSL certificates exist
if [ ! -f "$PROJECT_DIR/traefik/certs/aspiredev.local.pem" ]; then
    echo -e "${YELLOW}SSL certificates not found. Running setup...${NC}"
    bash "$SCRIPT_DIR/setup-ssl.sh"
    echo ""
fi

# Start docker-compose services
echo -e "${BLUE}Starting infrastructure services...${NC}"
cd "$PROJECT_DIR"
docker-compose up -d

# Wait for database to be ready
echo -e "${BLUE}Waiting for database to be ready...${NC}"
timeout 60 bash -c 'until docker exec cloudfest-aspirecloud-db pg_isready -U postgres > /dev/null 2>&1; do sleep 2; done' || {
    echo -e "${RED}Database failed to start${NC}"
    exit 1
}

# Check if database needs importing
DB_IMPORTED=$(docker exec cloudfest-aspirecloud-db psql -U postgres -d aspirecloud -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null | xargs || echo "0")

if [ "$DB_IMPORTED" -lt 5 ]; then
    echo -e "${YELLOW}Database appears empty. Importing snapshot...${NC}"
    bash "$SCRIPT_DIR/import-database.sh"
else
    echo -e "${GREEN}Database already populated.${NC}"
fi

# Initialize AspireCloud
echo -e "${BLUE}Initializing AspireCloud application...${NC}"
bash "$SCRIPT_DIR/init-aspirecloud.sh"
echo ""

# Start WordPress environment
echo -e "${BLUE}Starting WordPress environment...${NC}"
npm run wp:start

echo ""
echo -e "${GREEN}Environment started successfully!${NC}"
echo ""
echo "=================================================="
echo -e "${GREEN}Access Your Services:${NC}"
echo "=================================================="
echo ""
echo "WordPress:"
echo "  - Site: http://localhost:8888"
echo "  - Admin: http://localhost:8888/wp-admin"
echo "    Username: admin"
echo "    Password: password"
echo ""
echo "AspireCloud:"
echo "  - API: https://api.aspiredev.local"
echo "  - Direct: http://localhost:8099"
echo ""
echo "Development Tools:"
echo "  - Mailhog: https://mail.aspiredev.local (or http://localhost:8025)"
echo "  - Adminer: https://db.aspiredev.local (or http://localhost:8080)"
echo "  - Traefik Dashboard: http://localhost:8090"
echo ""
echo "=================================================="
echo -e "${YELLOW}Hackathon Resources:${NC}"
echo "=================================================="
echo ""
echo "Documentation:"
echo "  - docs/fair-pm-hackathon-guide.md"
echo "  - docs/patchstack-hackathon-guide.md"
echo ""
echo "Test the setup:"
echo "  curl https://api.aspiredev.local/plugins/info/1.1/"
echo ""
echo "View logs:"
echo "  npm run dev:logs"
echo ""
