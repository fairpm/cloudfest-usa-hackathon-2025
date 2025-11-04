#!/usr/bin/env bash
#
# wp-env afterStart lifecycle script
# Runs after WordPress containers start
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/wp-env-after-start.log"

# Log to both stdout and file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[afterStart] Running wp-env afterStart tasks at $(date)..."

# Wait a moment for containers to fully initialize
sleep 2

# Get WordPress container IDs
echo "[afterStart] Finding WordPress containers..."
WORDPRESS_DEV=$(docker ps --filter 'name=.*-wordpress-1' --format '{{.Names}} {{.ID}}' | grep -v 'tests-wordpress' | head -1 | awk '{print $2}')
WORDPRESS_TEST=$(docker ps -qf 'name=.*-tests-wordpress-1' | head -1)

if [ -z "$WORDPRESS_DEV" ]; then
    echo "[afterStart] ERROR: Could not find WordPress development container"
    exit 1
fi

echo "[afterStart] Found containers: dev=$WORDPRESS_DEV test=$WORDPRESS_TEST"

# Connect WordPress containers to cloudfest-network
echo "[afterStart] Connecting WordPress containers to cloudfest-network..."

# Ensure cloudfest-network exists
if ! docker network inspect cloudfest-network >/dev/null 2>&1; then
    echo "[afterStart] WARNING: cloudfest-network does not exist. Creating it..."
    docker network create cloudfest-network
fi

# Connect dev container (disconnect first to ensure clean state)
docker network disconnect cloudfest-network "$WORDPRESS_DEV" 2>/dev/null || true
docker network connect cloudfest-network "$WORDPRESS_DEV" 2>&1 | grep -v "already exists" || echo "[afterStart]   Dev container connected to cloudfest-network"

# Connect test container if it exists
if [ -n "$WORDPRESS_TEST" ]; then
    docker network disconnect cloudfest-network "$WORDPRESS_TEST" 2>/dev/null || true
    docker network connect cloudfest-network "$WORDPRESS_TEST" 2>&1 | grep -v "already exists" || echo "[afterStart]   Test container connected to cloudfest-network"
fi

# Ensure mu-plugins directory exists and copy config
echo "[afterStart] Setting up mu-plugins..."
docker exec "$WORDPRESS_DEV" bash -c "mkdir -p /var/www/html/wp-content/mu-plugins && chown www-data:www-data /var/www/html/wp-content/mu-plugins"
docker cp "$PROJECT_DIR/config/fair-config.php" "$WORDPRESS_DEV:/var/www/html/wp-content/mu-plugins/fair-config.php"
docker exec "$WORDPRESS_DEV" chown www-data:www-data /var/www/html/wp-content/mu-plugins/fair-config.php

# Verify the file was copied
echo "[afterStart] Verifying mu-plugin installation..."
docker exec "$WORDPRESS_DEV" ls -la /var/www/html/wp-content/mu-plugins/

echo "[afterStart] wp-env afterStart tasks complete!"
