#!/usr/bin/env bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}CloudFest Hackathon - Stopping Development Environment${NC}"
echo "========================================================="
echo ""

# Stop WordPress environment
echo -e "${BLUE}Stopping WordPress environment...${NC}"
npm run wp:stop || true

# Stop docker-compose services
echo -e "${BLUE}Stopping infrastructure services...${NC}"
cd "$PROJECT_DIR"
docker-compose down

echo ""
echo -e "${GREEN}Environment stopped successfully!${NC}"
