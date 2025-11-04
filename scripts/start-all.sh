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

# Detect docker compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose --version &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    echo -e "${RED}Error: Neither 'docker compose' nor 'docker-compose' found${NC}"
    exit 1
fi

# Start docker-compose services
echo -e "${BLUE}Starting infrastructure services...${NC}"
cd "$PROJECT_DIR"
$DOCKER_COMPOSE up -d

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

# Check if required directories exist
echo -e "${BLUE}Checking required directories...${NC}"

if [ ! -d "$PROJECT_DIR/aspirecloud" ]; then
    echo -e "${RED}ERROR: ./aspirecloud directory not found${NC}"
    echo "Please clone the AspireCloud repository:"
    echo "  git clone https://github.com/aspirepress/AspireCloud.git aspirecloud"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/cve-labeller" ]; then
    echo -e "${RED}ERROR: ./cve-labeller directory not found${NC}"
    echo "Please clone the CVE Labeller repository:"
    echo "  git clone git@github.com:fairpm/cve-labeller.git cve-labeller"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/fair-plugin" ]; then
    echo -e "${YELLOW}WARNING: ./fair-plugin directory not found${NC}"
    echo "Clone it to enable local plugin development:"
    echo "  git clone https://github.com/fairpm/fair-plugin.git fair-plugin"
    echo ""
fi

echo -e "${GREEN}✓ Required directories found${NC}"
echo ""

# Initialize AspireCloud
echo -e "${BLUE}Initializing AspireCloud application...${NC}"
bash "$SCRIPT_DIR/init-aspirecloud.sh"
echo ""

# Wait for CVE Labeller database to be ready
echo -e "${BLUE}Waiting for CVE Labeller database to be ready...${NC}"
timeout 60 bash -c 'until docker exec cloudfest-cve-labeller-db pg_isready -U postgres > /dev/null 2>&1; do sleep 2; done' || {
    echo -e "${RED}CVE Labeller database failed to start${NC}"
    exit 1
}

# Initialize CVE Labeller
echo -e "${BLUE}Initializing CVE Labeller application...${NC}"
bash "$SCRIPT_DIR/init-cve-labeller.sh"
echo ""

# Initialize FAIR Plugin if it exists
if [ -d "$PROJECT_DIR/fair-plugin" ]; then
    echo -e "${BLUE}Initializing FAIR Plugin...${NC}"
    bash "$SCRIPT_DIR/init-fair-plugin.sh"
    echo ""
fi

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
echo "CVE Labeller:"
echo "  - API: https://api.cve-labeller.local"
echo "  - Direct: http://localhost:8199"
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
