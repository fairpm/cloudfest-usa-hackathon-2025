# Hackathon Development Workflow

This guide provides the day-to-day workflow for developers during the CloudFest USA 2025 hackathon.

## Table of Contents
1. [First-Time Setup](#first-time-setup)
2. [Daily Startup](#daily-startup)
3. [Adding a New Service](#adding-a-new-service)
4. [Testing Your Service](#testing-your-service)
5. [Working with WordPress](#working-with-wordpress)
6. [Debugging & Troubleshooting](#debugging--troubleshooting)
7. [Stopping Services](#stopping-services)
8. [Quick Reference](#quick-reference)

## First-Time Setup

### Prerequisites
- Docker Desktop installed and running
- Node.js 18+ installed
- Git installed
- Terminal/command line access

### Initial Setup (Run Once)
```bash
# 1. Clone the repository
git clone <repository-url>
cd cloudfest-usa-2025-local-env

# 2. Install dependencies
npm install

# 3. Create environment file
cp .env.example .env

# 4. Start everything (this will take 5-10 minutes on first run)
npm run dev:start
```

**What happens during `dev:start`:**
1. Generates SSL certificates (mkcert)
2. Creates Docker network (`cloudfest-network`)
3. Starts infrastructure services (AspireCloud, PostgreSQL, Redis, Traefik)
4. Imports AspireCloud database snapshot
5. Starts WordPress environment

**Expected output:**
```
✅ SSL certificates generated
✅ Docker network created
✅ Services started: aspirecloud, redis, postgres, traefik
✅ Database imported (24MB)
✅ WordPress started

🌐 WordPress: http://localhost:8888
🔐 Admin: http://localhost:8888/wp-admin (admin/password)
📦 AspireCloud: http://localhost:8099
📧 Mailhog: http://localhost:8025
```

### Verify Installation
```bash
# Check all services are running
docker ps | grep cloudfest

# Test AspireCloud API
curl http://localhost:8099/plugins/info/1.1/

# Test WordPress
curl http://localhost:8888

# Test Redis
docker exec cloudfest-redis redis-cli PING
# Expected: PONG
```

## Daily Startup

### Starting All Services
```bash
# Start core infrastructure + WordPress
npm run dev:start
```

This is **idempotent** - safe to run multiple times. It will:
- Skip SSL setup if certificates exist
- Skip database import if already populated
- Start only stopped services

### Starting Only What You Need

**If you only need WordPress:**
```bash
npm run wp:start
```

**If you only need infrastructure (no WordPress):**
```bash
npm run docker:up
```

**If you need to add your team's services:**
```bash
# Start core + your team services
docker-compose -f docker-compose.yml -f docker-compose.backend.yml up -d
```

## Adding a New Service

### Step 1: Create Service Directory
```bash
# Create directory structure
mkdir -p services/your-team/your-service/{src,config}
cd services/your-team/your-service

# Create essential files
touch Dockerfile
touch .env.example
touch README.md
```

### Step 2: Write Your Application
```bash
# Example: Create a simple Node.js API
cat > src/index.js <<'EOF'
const express = require('express');
const app = express();
const PORT = process.env.SERVICE_PORT || 8100;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'my-service', timestamp: new Date() });
});

app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from my service!' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Service listening on port ${PORT}`);
});
EOF

cat > package.json <<'EOF'
{
  "name": "my-service",
  "version": "1.0.0",
  "main": "src/index.js",
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF
```

### Step 3: Create Dockerfile
```bash
# Use Node.js template from docs/templates/Dockerfile.nodejs
cp ../../docs/templates/Dockerfile.nodejs ./Dockerfile

# Or create your own
cat > Dockerfile <<'EOF'
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY src/ ./src/

EXPOSE 8100

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8100/health || exit 1

CMD ["node", "src/index.js"]
EOF
```

### Step 4: Add to docker-compose File
```bash
# Create or edit your team's compose file
cat > ../../docker-compose.backend.yml <<'EOF'
version: '3.8'

services:
  my-service:
    build:
      context: ./services/your-team/your-service
      dockerfile: Dockerfile
    container_name: cloudfest-my-service
    restart: unless-stopped
    environment:
      SERVICE_NAME: my-service
      SERVICE_PORT: 8100
      ASPIRECLOUD_API_URL: http://aspirecloud:80
      REDIS_URL: redis://redis:6379/1
      NODE_ENV: development
    ports:
      - "8100:8100"
    networks:
      - cloudfest-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8100/health"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  cloudfest-network:
    external: true
EOF
```

### Step 5: Start Your Service
```bash
# Return to repository root
cd ../../..

# Start your service
docker-compose -f docker-compose.yml -f docker-compose.backend.yml up -d my-service

# Follow logs
docker logs cloudfest-my-service -f
```

### Step 6: Test Your Service
```bash
# Test health endpoint
curl http://localhost:8100/health

# Test API endpoint
curl http://localhost:8100/api/hello

# Test from another container
docker exec cloudfest-aspirecloud curl http://my-service:8100/health
```

## Testing Your Service

### Basic HTTP Tests
```bash
# Health check
curl -i http://localhost:8100/health

# POST request with JSON
curl -X POST http://localhost:8100/api/scan \
  -H "Content-Type: application/json" \
  -d '{"plugin":"woocommerce","version":"8.5.0"}'

# GET with query parameters
curl "http://localhost:8100/api/status?plugin=woocommerce"
```

### Testing Inter-Service Communication
```bash
# Test from WordPress container
docker exec -it $(docker ps -qf 'name=.*-wordpress-1' | head -1) bash
curl http://my-service:8100/health
curl http://aspirecloud:80/plugins/info/1.1/
exit

# Test from your service to AspireCloud
docker exec cloudfest-my-service curl http://aspirecloud:80/plugins/info/1.1/

# Test Redis connection
docker exec cloudfest-my-service sh -c 'apk add redis && redis-cli -h redis PING'
```

### Testing Redis Pub/Sub
```bash
# Terminal 1: Subscribe to channel
docker exec -it cloudfest-redis redis-cli
SUBSCRIBE channel:events

# Terminal 2: Publish message
docker exec -it cloudfest-redis redis-cli
PUBLISH channel:events '{"event":"test","timestamp":1234567890}'

# You should see the message in Terminal 1
```

### Testing Database Connections
```bash
# Test AspireCloud database
docker exec cloudfest-aspirecloud-db psql -U postgres -d aspirecloud -c "SELECT COUNT(*) FROM plugins;"

# Test your own database (if you created one)
docker exec cloudfest-my-service-db psql -U postgres -d mydb -c "SELECT 1;"
```

## Working with WordPress

### Accessing WordPress
- **Frontend**: http://localhost:8888
- **Admin**: http://localhost:8888/wp-admin (admin/password)

### Installing Plugins via FAIR
```bash
# 1. Go to WordPress admin
# 2. Navigate to Plugins → Add New
# 3. Search for a plugin (e.g., "WooCommerce")
# 4. FAIR will intercept and query AspireCloud
# 5. Check logs to see FAIR in action:

npm run wp:logs
```

### WP-CLI Commands
```bash
# List installed plugins
npm run wp:cli -- plugin list

# Activate FAIR plugin
npm run wp:cli -- plugin activate aspirepress-plugin-manager

# Check FAIR configuration
npm run wp:cli -- eval "print_r(get_option('aspirepress_settings'));"

# Clear WordPress cache
npm run wp:cli -- cache flush
```

### Modifying FAIR Configuration
```bash
# Edit the FAIR config file
nano config/fair-config.php

# Changes require WordPress restart
npm run wp:stop
npm run wp:start

# Verify configuration
npm run wp:cli -- eval "print_r(defined('ASPIREPRESS_API_HOST'));"
```

### Accessing WordPress Filesystem
```bash
# Enter WordPress container
docker exec -it $(docker ps -qf 'name=.*-wordpress-1' | head -1) bash

# Navigate to plugins directory
cd /var/www/html/wp-content/plugins

# View FAIR plugin files
ls -la aspirepress-plugin-manager/

# View debug log
tail -f /var/www/html/wp-content/debug.log

# Exit container
exit
```

## Debugging & Troubleshooting

### Viewing Logs

**All services:**
```bash
npm run dev:logs
```

**Specific service:**
```bash
docker logs cloudfest-aspirecloud -f
docker logs cloudfest-my-service -f
docker logs cloudfest-aspirecloud-db -f
```

**WordPress logs:**
```bash
npm run wp:logs

# Or access debug.log directly
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) tail -f /var/www/html/wp-content/debug.log
```

**Last 100 lines:**
```bash
docker logs cloudfest-aspirecloud --tail 100
```

**Follow logs for multiple services:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.backend.yml logs -f my-service aspirecloud
```

### Checking Service Health

**List all running services:**
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

**Check specific service health:**
```bash
docker inspect cloudfest-my-service --format='{{.State.Health.Status}}'
# Expected: healthy
```

**Inspect network:**
```bash
docker network inspect cloudfest-network | grep -A 5 "Containers"
```

### Common Issues

**Port already in use:**
```bash
# Find what's using the port
lsof -i :8100

# Stop the conflicting service or change your port
```

**Service can't connect to AspireCloud:**
```bash
# 1. Verify AspireCloud is running
docker ps | grep aspirecloud

# 2. Test from your service container
docker exec cloudfest-my-service curl http://aspirecloud:80/health

# 3. Check if on same network
docker network inspect cloudfest-network
```

**Database connection fails:**
```bash
# 1. Check database is healthy
docker ps | grep postgres

# 2. Wait for database to be ready
docker-compose ps
# Look for "healthy" status

# 3. Test connection
docker exec cloudfest-aspirecloud-db pg_isready -U postgres
```

**Service won't start:**
```bash
# 1. Check logs for errors
docker logs cloudfest-my-service

# 2. Rebuild the image
docker-compose -f docker-compose.backend.yml build --no-cache my-service

# 3. Start with verbose output
docker-compose -f docker-compose.backend.yml up my-service
```

### Rebuilding After Code Changes

**Rebuild and restart a service:**
```bash
# Stop service
docker-compose -f docker-compose.backend.yml stop my-service

# Rebuild image
docker-compose -f docker-compose.backend.yml build my-service

# Start service
docker-compose -f docker-compose.backend.yml up -d my-service

# Or all in one command
docker-compose -f docker-compose.backend.yml up -d --build my-service
```

**Force complete rebuild (no cache):**
```bash
docker-compose -f docker-compose.backend.yml build --no-cache my-service
docker-compose -f docker-compose.backend.yml up -d my-service
```

### Resetting Environment

**Reset WordPress (keeps infrastructure):**
```bash
npm run wp:destroy
npm run wp:start
```

**Reset AspireCloud database:**
```bash
# Stop AspireCloud
docker-compose stop aspirecloud

# Drop database
docker exec cloudfest-aspirecloud-db psql -U postgres -c "DROP DATABASE aspirecloud;"
docker exec cloudfest-aspirecloud-db psql -U postgres -c "CREATE DATABASE aspirecloud;"

# Re-import snapshot
npm run db:import

# Restart AspireCloud
docker-compose up -d aspirecloud
```

**Full environment reset:**
```bash
# ⚠️  WARNING: This deletes ALL data
npm run dev:reset

# Then start fresh
npm run dev:start
```

## Stopping Services

### Stop Everything
```bash
npm run dev:stop
```

### Stop Specific Components

**Stop WordPress only:**
```bash
npm run wp:stop
```

**Stop infrastructure only:**
```bash
npm run docker:down
```

**Stop your team services:**
```bash
docker-compose -f docker-compose.backend.yml down
```

**Stop specific service (keep others running):**
```bash
docker-compose -f docker-compose.backend.yml stop my-service
```

### Cleanup

**Remove stopped containers:**
```bash
docker container prune
```

**Remove unused images:**
```bash
docker image prune
```

**Remove everything (nuclear option):**
```bash
docker system prune -a --volumes
# ⚠️  WARNING: This removes ALL Docker data
```

## Quick Reference

### Essential Commands
```bash
# Start everything
npm run dev:start

# Stop everything
npm run dev:stop

# View logs
npm run dev:logs

# Start WordPress only
npm run wp:start

# WP-CLI commands
npm run wp:cli -- <command>

# List running services
docker ps

# Follow service logs
docker logs <container-name> -f

# Rebuild service
docker-compose -f docker-compose.<team>.yml up -d --build <service>
```

### Service URLs
| Service | URL | Credentials |
|---------|-----|-------------|
| WordPress | http://localhost:8888 | admin/password |
| WordPress Admin | http://localhost:8888/wp-admin | admin/password |
| AspireCloud API | http://localhost:8099 | - |
| Mailhog | http://localhost:8025 | - |
| Adminer (DB UI) | http://localhost:8080 | postgres/password |
| Traefik Dashboard | http://localhost:8090 | - |

### Common Curl Commands
```bash
# AspireCloud: Get plugin info
curl http://localhost:8099/plugins/info/1.1/ | jq

# PatchStack: Check vulnerabilities
curl -X POST https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${PATCHSTACK_API_TOKEN}" \
  -d '[{"type":"plugin","name":"woocommerce","version":"8.0.0"}]' | jq

# Your service: Health check
curl http://localhost:8100/health | jq
```

### Docker Network Commands
```bash
# List networks
docker network ls

# Inspect cloudfest network
docker network inspect cloudfest-network

# See which containers are on the network
docker network inspect cloudfest-network --format='{{range .Containers}}{{.Name}} {{end}}'
```

### Useful Aliases (Optional)
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
# Hackathon-specific aliases
alias cf-start='npm run dev:start'
alias cf-stop='npm run dev:stop'
alias cf-logs='npm run dev:logs'
alias cf-wp='npm run wp:cli --'
alias cf-ps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias cf-network='docker network inspect cloudfest-network'
```

## Team Workflows

### Backend Team Workflow
```bash
# Day 1: Setup
npm run dev:start
docker-compose -f docker-compose.yml -f docker-compose.backend.yml up -d

# Day 2-N: Development cycle
# 1. Edit code in services/backend/*
# 2. Rebuild service:
docker-compose -f docker-compose.backend.yml up -d --build vuln-scanner
# 3. Test:
curl http://localhost:8100/api/scan -d '{"plugin":"woocommerce"}'
# 4. View logs:
docker logs cloudfest-vuln-scanner -f
```

### Frontend Team Workflow
```bash
# Day 1: Setup
npm run dev:start
docker-compose -f docker-compose.yml -f docker-compose.frontend.yml up -d

# Development (hot reload example)
cd services/frontend/dashboard
npm run dev  # Runs on localhost:8200 with hot reload

# Production build
docker-compose -f docker-compose.frontend.yml up -d --build dashboard
```

### Full-Stack Integration Testing
```bash
# Terminal 1: Follow all logs
npm run dev:logs

# Terminal 2: Follow your service logs
docker logs cloudfest-my-service -f

# Terminal 3: Run test commands
curl http://localhost:8100/api/test
```

## Next Steps

1. Review `docs/ADDING-SERVICES.md` for detailed service integration guide
2. Check `docs/ARCHITECTURE.md` for system architecture overview
3. Explore `services/examples/hello-world-api/` for working example
4. Start building your hackathon service!

## Getting Help

**Check service status:**
```bash
docker ps
docker logs <container-name>
```

**Test connectivity:**
```bash
docker network inspect cloudfest-network
docker exec <container> curl http://<other-service>:port/health
```

**Reset and try again:**
```bash
npm run dev:stop
npm run dev:start
```

If issues persist, check:
- Docker Desktop is running
- Ports aren't already in use
- Services are on `cloudfest-network`
- Environment variables are set correctly
