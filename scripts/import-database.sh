#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNAPSHOTS_DIR="$PROJECT_DIR/snapshots"

echo -e "${GREEN}CloudFest Hackathon - AspireCloud Database Import${NC}"
echo "=================================================="
echo ""

# Check if database container is running
if ! docker ps | grep -q cloudfest-aspirecloud-db; then
    echo -e "${RED}Error: AspireCloud database container is not running.${NC}"
    echo "Please start the services first with: npm run dev:start"
    exit 1
fi

# Find SQL file
SQL_FILE=""
if [ -f "$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql" ]; then
    SQL_FILE="$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql"
elif [ -f "$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql.zst" ]; then
    echo -e "${YELLOW}Found compressed snapshot. Decompressing...${NC}"
    if command -v zstd &> /dev/null; then
        zstd -d "$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql.zst" -o "$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql"
        SQL_FILE="$SNAPSHOTS_DIR/aspirecloud_mini_20251029.sql"
    else
        echo -e "${RED}Error: zstd is not installed. Please install it first.${NC}"
        echo ""
        echo "Installation:"
        echo "  macOS: brew install zstd"
        echo "  Linux: sudo apt-get install zstd"
        exit 1
    fi
else
    echo -e "${RED}Error: No SQL snapshot found in $SNAPSHOTS_DIR${NC}"
    echo "Expected: aspirecloud_mini_20251029.sql or aspirecloud_mini_20251029.sql.zst"
    exit 1
fi

echo -e "${YELLOW}Importing database from: $(basename $SQL_FILE)${NC}"
echo ""

# Import using docker exec
echo "This may take a few minutes..."
docker exec -i cloudfest-aspirecloud-db psql -U postgres -d aspirecloud < "$SQL_FILE"

echo ""
echo -e "${GREEN}Database imported successfully!${NC}"
echo ""
echo "AspireCloud is now ready to use with the imported data."
echo "Access it at: https://api.aspiredev.local"
