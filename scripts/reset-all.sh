#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${RED}CloudFest Hackathon - Reset Development Environment${NC}"
echo "====================================================="
echo ""
echo -e "${YELLOW}WARNING: This will delete all data and reset the environment!${NC}"
echo ""
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""

# Stop and destroy WordPress environment
echo "Destroying WordPress environment..."
npm run wp:destroy || true

# Stop and remove docker-compose services and volumes
echo "Removing infrastructure services and volumes..."
cd "$PROJECT_DIR"
docker-compose down -v

# Remove node_modules if requested
read -p "Also remove node_modules? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing node_modules..."
    rm -rf "$PROJECT_DIR/node_modules"
fi

echo ""
echo -e "${GREEN}Environment reset complete!${NC}"
echo ""
echo "To start fresh:"
echo "  npm install"
echo "  npm run dev:start"
