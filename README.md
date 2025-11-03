# CloudFest USA 2025 - Hackathon Development Environment

**FAIR Package Manager + AspireCloud + PatchStack Integration**

This is a complete local development environment for the CloudFest USA 2025 Hackathon, featuring:
- **WordPress** with wp-env
- **FAIR Plugin** for federated package management
- **AspireCloud** local API instance
- **PatchStack** vulnerability API integration
- **Traefik** reverse proxy with SSL
- **Development tools** (Redis, Mailhog, Adminer)

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Services & Access](#services--access)
- [Architecture](#architecture)
- [Hackathon Resources](#hackathon-resources)
- [Available Commands](#available-commands)
- [Configuration](#configuration)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker Desktop** - Running and configured with at least 4GB RAM
- **Node.js** v18 or later
- **npm** or yarn
- **Git**
- **zstd** (for database decompression)
  - macOS: `brew install zstd`
  - Linux: `sudo apt-get install zstd`

### System Requirements

- 8GB RAM minimum (16GB recommended)
- 20GB free disk space
- macOS or Linux (WSL2 on Windows)

## Quick Start

### 1. Clone and Install

```bash
# Install Node dependencies
npm install
```

### 2. One-Command Setup

```bash
# This will:
# - Start all services (AspireCloud, Traefik, Redis, etc.)
# - Import the AspireCloud database
# - Start WordPress with FAIR plugin
# - Connect WordPress to the AspireCloud network
npm run dev:start
```

The setup script will:
- Start all Docker services
- Import the AspireCloud database
- Launch WordPress with FAIR plugin pre-installed
- Configure FAIR to use the local AspireCloud instance

### 3. Access Your Environment

Once started, you can access:

- **WordPress**: http://localhost:8888
  - Admin: http://localhost:8888/wp-admin
  - Username: `admin` / Password: `password`
- **AspireCloud API**: http://localhost:8099
- **Mailhog**: http://localhost:8025
- **Adminer (Database)**: http://localhost:8080
- **Traefik Dashboard**: http://localhost:8090

## Services & Access

### Core Services

| Service     | Browser URL           | Docker Network URL      | Purpose                                |
|-------------|-----------------------|-------------------------|----------------------------------------|
| WordPress   | http://localhost:8888 | N/A                     | Main development site with FAIR plugin |
| AspireCloud | http://localhost:8099 | http://aspirecloud:80   | Local WordPress package API            |
| Mailhog UI  | http://localhost:8025 | http://mailhog:8025     | Email testing interface                |
| Adminer     | http://localhost:8080 | N/A                     | Database management                    |
| Traefik     | http://localhost:8090 | N/A                     | Reverse proxy dashboard                |
| Redis       | localhost:6379        | redis:6379              | Cache service                          |
| PostgreSQL  | localhost:5432        | aspirecloud-db:5432     | AspireCloud database                   |

**Note:** WordPress accesses AspireCloud via Docker network (`http://aspirecloud:80`), while your browser uses `http://localhost:8099`.

### Default Credentials

**WordPress:**
- Username: `admin`
- Password: `password`

**PostgreSQL (AspireCloud):**
- Host: `localhost` or `aspirecloud-db`
- Database: `aspirecloud`
- Username: `postgres`
- Password: `password`

**MySQL (WordPress via wp-env):**
- Host: `localhost`
- Database: `wordpress`
- Username: `root`
- Password: `password`

## Architecture

### Docker Network Architecture

```
┌───────────────────────────────────────────────────────────┐
│                    cloudfest-network                      │
│                                                           │
│  ┌──────────┐  ┌────────────┐  ┌──────────┐  ┌─────────┐  │
│  │  Traefik │  │ AspireCloud│  │ WordPress│  │  Redis  │  │
│  │  (SSL)   │─▶│   (API)    │◀─│ (wp-env) │◀─│ (Cache) │  │
│  └────┬─────┘  └─────┬──────┘  └────┬─────┘  └─────────┘  │
│       │              │              │                     │
│       │         ┌────▼─────┐    ┌───▼────┐                │
│       │         │PostgreSQL│    │ MySQL  │                │
│       │         └──────────┘    └────────┘                │
│       │                                                   │
│       │         ┌─────────┐    ┌─────────┐                │
│       └────────▶│ Mailhog │    │ Adminer │                │
│                 └─────────┘    └─────────┘                │
└───────────────────────────────────────────────────────────┘
```

### Data Flow

1. **FAIR Plugin** → Queries local **AspireCloud** API via Docker network (`http://aspirecloud:80`)
2. **AspireCloud** → Serves WordPress packages from **PostgreSQL**
3. **WordPress** → Uses **Redis** for caching
4. **Browser** → Accesses services via port-based URLs (`http://localhost:*`)

### File Structure

```
.
├── .wp-env.json              # WordPress environment config
├── docker-compose.yml        # Infrastructure services
├── package.json              # Node scripts and dependencies
├── .env.example              # Environment variables template
├── config/
│   └── fair-config.php       # FAIR plugin auto-configuration
├── docs/
│   ├── fair-pm-hackathon-guide.md
│   └── patchstack-hackathon-guide.md
├── scripts/
│   ├── setup-ssl.sh          # SSL certificate setup
│   ├── start-all.sh          # Start everything
│   ├── stop-all.sh           # Stop everything
│   ├── reset-all.sh          # Reset environment
│   └── import-database.sh    # Import AspireCloud DB
├── snapshots/
│   └── aspirecloud_mini_*.sql # AspireCloud database snapshot
└── traefik/
    ├── certs/                # SSL certificates (generated)
    └── dynamic/
        └── tls.yml           # Traefik TLS config
```

## Hackathon Resources

### Documentation

All hackathon documentation is available in the `docs/` directory:

- **docs/fair-pm-hackathon-guide.md** - FAIR Protocol, DIDs, Package metadata
- **docs/patchstack-hackathon-guide.md** - Vulnerability API integration

### PatchStack API

The environment includes the PatchStack API token for vulnerability testing:

**Endpoint:** `https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon`

**Example Request:**
```bash
curl -X POST https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer aapi_CN2ZAQdQBC72RXBKqpO5BnAscEGuDyBqxrd0icqlO3NkWfENSlkk1sGv4xq9kbBv" \
  -d '[{"type":"plugin","name":"woocommerce","version":"1.0.0","exists":false}]'
```

### Testing AspireCloud

```bash
# Test the local AspireCloud API
curl http://localhost:8099/plugins/info/1.1/

# Query for specific plugins
curl "http://localhost:8099/plugins/info/1.1/?action=query_plugins&request[per_page]=5"
```

### Testing FAIR Plugin

The FAIR plugin is pre-installed and configured to use your local AspireCloud instance. Check the configuration:

1. Log into WordPress admin: http://localhost:8888/wp-admin
2. Navigate to Plugins - you should see "FAIR" plugin active
3. Check debug logs: `npm run wp:logs`

## Available Commands

### Quick Commands (Recommended)

```bash
npm run dev:start      # Start everything (SSL setup + all services)
npm run dev:stop       # Stop all services
npm run dev:reset      # Complete reset (deletes all data!)
npm run dev:logs       # Follow all service logs
```

### Setup & Maintenance

```bash
npm run setup          # Run SSL certificate setup only
npm run db:import      # Import AspireCloud database
```

### WordPress Commands

```bash
npm run wp:start       # Start WordPress only
npm run wp:stop        # Stop WordPress only
npm run wp:destroy     # Destroy WordPress environment
npm run wp:clean       # Clean WordPress (reset to fresh install)
npm run wp:logs        # View WordPress logs
npm run wp:cli         # Run WP-CLI commands
```

**WP-CLI Examples:**
```bash
# List plugins
npm run wp:cli -- plugin list

# Activate FAIR plugin
npm run wp:cli -- plugin activate fair-plugin

# Create test posts
npm run wp:cli -- post generate --count=10
```

### Docker Commands

```bash
npm run docker:up      # Start infrastructure services only
npm run docker:down    # Stop infrastructure services
npm run docker:logs    # Follow infrastructure logs
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key variables:
- `PATCHSTACK_API_TOKEN` - Your PatchStack API token
- `ASPIRECLOUD_API_URL` - Local AspireCloud API URL (default: http://aspirecloud:80 for Docker network)

### Customizing WordPress

Edit `.wp-env.json`:

```json
{
  "plugins": [
    "https://github.com/fairpm/fair-plugin/archive/refs/heads/main.zip",
    "https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip"
  ],
  "themes": [
    "https://downloads.wordpress.org/theme/twentytwentyfour.zip"
  ]
}
```

### Customizing Infrastructure

Edit `docker-compose.yml` to:
- Add new services
- Change resource limits
- Modify environment variables
- Adjust port mappings

## Development Workflow

### Typical Hackathon Workflow

1. **Start Environment**
   ```bash
   npm run dev:start
   ```

2. **Develop Your Integration**
   - Create a WordPress plugin in `wp-content/plugins/`
   - Use FAIR APIs to query AspireCloud
   - Integrate PatchStack vulnerability data
   - Test with FAIR DID resolution

3. **Access WP Filesystem**
   ```bash
   # WordPress files are in wp-env volumes
   # Access via WP-CLI or map a local directory
   docker exec -it $(docker ps -qf 'name=.*-wordpress-1') bash
   ```

4. **Monitor Logs**
   ```bash
   # All services
   npm run dev:logs

   # WordPress only
   npm run wp:logs

   # AspireCloud only
   docker logs -f cloudfest-aspirecloud
   ```

5. **Test Your Changes**
   - WordPress: http://localhost:8888
   - AspireCloud API: http://localhost:8099
   - Check emails: http://localhost:8025

6. **Reset When Needed**
   ```bash
   npm run dev:reset
   npm run dev:start
   ```

### Working with FAIR

The FAIR plugin is automatically configured via `config/fair-config.php`. This file:
- Points FAIR to local AspireCloud (`http://aspirecloud:80` via Docker network)
- Enables debug logging
- Shows admin notices about the configuration

**Important:** WordPress accesses AspireCloud using the Docker container name `aspirecloud`, not `localhost`. This allows container-to-container communication on the `cloudfest-network`.

### Working with AspireCloud

**Database Access:**
```bash
# Via Adminer: http://localhost:8080
# Select: PostgreSQL, Server: aspirecloud-db, User: postgres, Password: password

# Via command line:
docker exec -it cloudfest-aspirecloud-db psql -U postgres -d aspirecloud
```

**Re-import Database:**
```bash
npm run db:import
```

**View AspireCloud Logs:**
```bash
docker logs -f cloudfest-aspirecloud
```

## Troubleshooting

### WordPress Can't Connect to AspireCloud

1. Check if WordPress is on the cloudfest-network:
   ```bash
   docker network inspect cloudfest-network | grep wordpress
   ```

2. If not connected, manually connect:
   ```bash
   docker network connect cloudfest-network $(docker ps -qf 'name=.*-wordpress-1' | head -1)
   ```

3. Restart WordPress:
   ```bash
   npm run wp:stop && npm run wp:start
   ```

### Can't Access Services

All services are accessible via port-based URLs:

- **AspireCloud**: http://localhost:8099
- **Mailhog**: http://localhost:8025
- **Adminer**: http://localhost:8080
- **Traefik Dashboard**: http://localhost:8090
- **WordPress**: http://localhost:8888

If you can't access a service, check if the container is running:
```bash
docker ps | grep cloudfest
```

### Port Conflicts

If ports are already in use:

```bash
# Check what's using ports
lsof -i :80
lsof -i :443
lsof -i :8888

# Stop conflicting services or change ports in:
# - docker-compose.yml (for 80, 443, etc.)
# - .wp-env.json (for 8888, 8889)
```

### WordPress Won't Start

```bash
# Clean restart
npm run wp:destroy
npm run dev:start
```

### Database Import Fails

```bash
# Ensure services are running
docker ps

# Check database is ready
docker exec cloudfest-aspirecloud-db pg_isready -U postgres

# Manually import
docker exec -i cloudfest-aspirecloud-db psql -U postgres -d aspirecloud < snapshots/aspirecloud_mini_20251029.sql
```

### Docker Network Issues

```bash
# Reset Docker networks
docker network prune
docker-compose down
docker-compose up -d
npm run wp:start
```

### Complete Reset

When all else fails:

```bash
npm run dev:reset
# This will delete EVERYTHING and start fresh
```

## Advanced Topics

### Custom Plugin Development

Create a new plugin in the WordPress environment:

```bash
# Access WordPress container
docker exec -it $(docker ps -qf 'name=.*-wordpress-1') bash

# Navigate to plugins
cd /var/www/html/wp-content/plugins

# Create your plugin directory
mkdir my-hackathon-plugin
```

### Using Redis with WordPress

Install Redis Object Cache plugin:

```json
// In .wp-env.json, add to plugins array:
"https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip"
```

Configure in `wp-config.php` (via mu-plugin or wp-cli):
```php
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
```

### Email Testing with Mailhog

Configure SMTP in WordPress:
- SMTP Host: `mailhog`
- SMTP Port: `1025`
- No authentication required

All emails sent from WordPress will be captured in Mailhog UI: http://localhost:8025

### Accessing Service Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f aspirecloud
docker-compose logs -f traefik

# WordPress
npm run wp:logs
```

## Support & Resources

### Hackathon Support

- **FAIR Slack**: [chat.fair.pm](https://chat.fair.pm)
  - `#cloudfest-hackathon`
  - `#wg-aspirecloud`

### Documentation Links

- [FAIR Protocol](https://github.com/fairpm/fair-protocol)
- [FAIR Plugin](https://github.com/fairpm/fair-plugin)
- [AspireCloud](https://github.com/aspirepress/AspireCloud)
- [AspireCloud Docs](https://docs.aspirepress.org/aspirecloud/)
- [PatchStack](https://patchstack.com)
- [wp-env Documentation](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/)

### Common Issues

Check the [Troubleshooting](#troubleshooting) section above or:
- Review service logs: `npm run dev:logs`
- Check Docker: `docker ps -a`
- Verify network: `docker network inspect cloudfest-network`
- Reset everything: `npm run dev:reset`

## License

MIT - See LICENSE file for details

---

**Built for CloudFest USA 2025 Hackathon**
📍 Miami Marriott Biscayne Bay | November 4, 2025
Sponsored by PatchStack
