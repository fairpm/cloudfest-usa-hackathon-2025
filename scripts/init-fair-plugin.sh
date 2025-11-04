#!/usr/bin/env bash
#
# FAIR Plugin Initialization Script
# Ensures the plugin is ready for development
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_DIR="$PROJECT_DIR/fair-plugin"

echo -e "${BLUE}Initializing FAIR Plugin...${NC}"

# Check if plugin directory exists
if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${RED}ERROR: FAIR Plugin directory not found at $PLUGIN_DIR${NC}"
    echo "Clone it first:"
    echo "  git clone https://github.com/fairpm/fair-plugin.git fair-plugin"
    exit 1
fi

cd "$PLUGIN_DIR"

# Check for Composer dependencies
if [ -f "composer.json" ]; then
    echo -e "${YELLOW}Checking Composer dependencies...${NC}"
    if [ ! -f "vendor/autoload.php" ]; then
        echo -e "${YELLOW}Installing Composer dependencies...${NC}"
        composer install --no-interaction --prefer-dist --optimize-autoloader
    else
        echo -e "${GREEN}✓ Composer dependencies are installed${NC}"
    fi
fi

echo -e "${GREEN}FAIR Plugin initialization complete!${NC}"
echo ""
echo "The plugin is now ready for development."
