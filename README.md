# CloudFest USA 2025 - Hackathon Development Environment

**FAIR Package Manager + AspireCloud + CVE Labeller + PatchStack Integration**

This is a complete local development environment for the CloudFest USA 2025 Hackathon, featuring:
- **WordPress** with wp-env
- **FAIR Plugin** for federated package management (editable local copy)
- **AspireCloud** local API instance (editable local copy)
- **CVE Labeller** Laravel application for vulnerability labeling
- **PatchStack** vulnerability API integration
- **Traefik** reverse proxy with SSL
- **Development tools** (Redis, Mailhog, Adminer)

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Services & Access](#services--access)
- [Architecture](#architecture)
- [Local Development Setup](#local-development-setup)
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
- **Composer** (PHP dependency manager)
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
# Clone the environment repository
git clone <this-repository-url>
cd cloudfest-usa-2025-local-env

# Install Node dependencies
npm install
```

### 2. Clone Application Repositories

```bash
# Clone AspireCloud (required)
git clone https://github.com/aspirepress/AspireCloud.git aspirecloud

# Clone CVE Labeller (required)
git clone <cve-labeller-repo-url> cve-labeller

# Clone FAIR Plugin (optional - for local plugin development)
git clone https://github.com/fairpm/fair-plugin.git fair-plugin
```

### 3. Install Dependencies

```bash
# Install AspireCloud dependencies
cd aspirecloud
composer install
yarn install
cd ..

# Install CVE Labeller dependencies
cd cve-labeller
composer install
cd ..

# Install FAIR Plugin dependencies (if cloned)
cd fair-plugin
composer install
cd ..
```

### 4. One-Command Setup

```bash
# This will:
# - Generate SSL certificates
# - Start all services (AspireCloud, CVE Labeller, Traefik, Redis, etc.)
# - Import the AspireCloud database
# - Build frontend assets
# - Start WordPress with FAIR plugin
# - Connect everything to the network
npm run dev:start
```

The setup script will automatically:
- Start all Docker services
- Import the AspireCloud database
- Build AspireCloud frontend assets
- Initialize CVE Labeller database
- Automatically clone FAIR plugin from GitHub if not present
- Launch WordPress with FAIR plugin pre-installed
- Configure FAIR to use the local AspireCloud instance

### 5. Access Your Environment

Once started, you can access:

- **WordPress**: http://localhost:8888
    - Admin: http://localhost:8888/wp-admin
    - Username: `admin` / Password: `password`
- **AspireCloud API**: http://localhost:8099
- **CVE Labeller**: http://localhost:8199
- **Mailhog**: http://localhost:8025
- **Adminer (Database)**: http://localhost:8080
- **Traefik Dashboard**: http://localhost:8090

## Services & Access

### Core Services

| Service      | Browser URL           | Docker Network URL        | Purpose                                |
|--------------|-----------------------|---------------------------|----------------------------------------|
| WordPress    | http://localhost:8888 | N/A                       | Main development site with FAIR plugin |
| AspireCloud  | http://localhost:8099 | http://aspirecloud:80     | Local WordPress package API            |
| CVE Labeller | http://localhost:8199 | http://cve-labeller:80    | Vulnerability labeling application     |
| Mailhog UI   | http://localhost:8025 | http://mailhog:8025       | Email testing interface                |
| Adminer      | http://localhost:8080 | N/A                       | Database management                    |
| Traefik      | http://localhost:8090 | N/A                       | Reverse proxy dashboard                |
| Redis        | localhost:6379        | redis:6379                | Cache service (shared)                 |
| PostgreSQL   | localhost:5432        | aspirecloud-db:5432       | AspireCloud database                   |
| PostgreSQL   | localhost:5433        | cve-labeller-db:5432      | CVE Labeller database                  |

**Note:** WordPress accesses services via Docker network (e.g., `http://aspirecloud:80`), while your browser uses `http://localhost:8099`.

### Default Credentials

**WordPress:**
- Username: `admin`
- Password: `password`

**PostgreSQL (AspireCloud):**
- Host: `localhost` or `aspirecloud-db`
- Port: `5432`
- Database: `aspirecloud`
- Username: `postgres`
- Password: `password`

**PostgreSQL (CVE Labeller):**
- Host: `localhost` or `cve-labeller-db`
- Port: `5433`
- Database: `cve_labeller`
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
┌────────────────────────────────────────────────────────────────┐
│                      cloudfest-network                         │
│                                                                │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐  │
│  │  Traefik │  │ AspireCloud│  │CVE Labeller│  │WordPress │  │
│  │  (SSL)   │─▶│   (API)    │◀─│   (API)    │◀─│ (wp-env) │  │
│  └────┬─────┘  └─────┬──────┘  └─────┬──────┘  └────┬─────┘  │
│       │              │               │              │         │
│       │         ┌────▼─────┐    ┌────▼─────┐   ┌───▼────┐    │
│       │         │PostgreSQL│    │PostgreSQL│   │ MySQL  │    │
│       │         │(AspireC) │    │(CVE Lab) │   └────────┘    │
│       │         └──────────┘    └──────────┘                 │
│       │              │               │                        │
│       │         ┌────▼───────────────▼────┐                  │
│       │         │       Redis (Shared)     │                 │
│       │         └─────────────────────────┘                  │
│       │                                                       │
│       │         ┌─────────┐    ┌─────────┐                   │
│       └────────▶│ Mailhog │    │ Adminer │                   │
│                 └─────────┘    └─────────┘                   │
└────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **FAIR Plugin** → Queries local **AspireCloud** API via Docker network (`http://aspirecloud:80`)
2. **AspireCloud** → Serves WordPress packages from **PostgreSQL**
3. **CVE Labeller** → Manages vulnerability data in its own **PostgreSQL** database
4. **Both Laravel apps** → Use shared **Redis** for caching and sessions
5. **WordPress** → Uses **Redis** for object caching
6. **Browser** → Accesses services via port-based URLs (`http://localhost:*`)

### File Structure

```
.
├── .wp-env.json              # WordPress environment config
├── docker-compose.yml        # Infrastructure services
├── package.json              # Node scripts and dependencies
├── .env.example              # Environment variables template
├── aspirecloud/              # AspireCloud Laravel app (git cloned)
│   ├── app/
│   ├── resources/
│   ├── vendor/              # Composer dependencies
│   └── node_modules/        # Yarn dependencies
├── cve-labeller/             # CVE Labeller Laravel app (git cloned)
│   ├── app/
│   ├── resources/
│   └── vendor/              # Composer dependencies
├── fair-plugin/              # FAIR Plugin (optional, git cloned)
│   └── vendor/              # Composer dependencies
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
│   ├── init-aspirecloud.sh   # Initialize AspireCloud
│   ├── init-cve-labeller.sh  # Initialize CVE Labeller
│   ├── init-fair-plugin.sh   # Initialize FAIR Plugin
│   └── import-database.sh    # Import AspireCloud DB
├── snapshots/
│   └── aspirecloud_mini_*.sql # AspireCloud database snapshot
└── traefik/
    ├── certs/                # SSL certificates (generated)
    └── dynamic/
        └── tls.yml           # Traefik TLS config
```

## Local Development Setup

### Editable Applications

All three applications are mounted as editable directories:

**AspireCloud** (`./aspirecloud/`):
- Edit PHP code in `app/`, `routes/`, etc.
- Edit Blade templates in `resources/views/`
- Edit Vue components in `resources/js/`
- Run `yarn build` to rebuild assets after JS changes
- Changes are immediately reflected (clear Laravel cache if needed)

**CVE Labeller** (`./cve-labeller/`):
- Edit PHP code in `app/`, `routes/`, etc.
- Edit views in `resources/views/`
- Changes are immediately reflected

**FAIR Plugin** (`./fair-plugin/`):
- Edit plugin PHP code directly
- Changes are immediately reflected in WordPress
- No need to reinstall or reactivate

### Building Assets

After making changes to frontend code:

```bash
# Rebuild AspireCloud assets
docker exec -w /app cloudfest-aspirecloud yarn build

# Or from your host (if you have Node/Yarn installed)
cd aspirecloud
yarn build
cd ..
```

### Clearing Caches

```bash
# Clear AspireCloud cache
docker exec -w /app cloudfest-aspirecloud php artisan optimize:clear

# Clear CVE Labeller cache
docker exec -w /app cloudfest-cve-labeller php artisan optimize:clear

# Or use npm scripts
npm run aspirecloud:clear
npm run cve-labeller:clear
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

### Testing CVE Labeller

```bash
# Test the CVE Labeller API
curl http://localhost:8199/

# Access via Traefik (after SSL setup)
curl https://api.cve-labeller.local/
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

### Application-Specific Commands

```bash
# AspireCloud
npm run aspirecloud:init    # Initialize AspireCloud
npm run aspirecloud:clear   # Clear Laravel cache
npm run aspirecloud:update  # Pull latest image and reinitialize

# CVE Labeller
npm run cve-labeller:init   # Initialize CVE Labeller
npm run cve-labeller:clear  # Clear Laravel cache

# FAIR Plugin
npm run fair-plugin:init    # Initialize FAIR Plugin
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
    "./fair-plugin",  // Local editable plugin
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
    - Edit AspireCloud code in `./aspirecloud/`
    - Edit CVE Labeller code in `./cve-labeller/`
    - Edit FAIR Plugin code in `./fair-plugin/`
    - Create WordPress plugins for hackathon features

3. **Test Changes**
    - WordPress: http://localhost:8888
    - AspireCloud API: http://localhost:8099
    - CVE Labeller: http://localhost:8199
    - Check emails: http://localhost:8025

4. **Monitor Logs**
   ```bash
   # All services
   npm run dev:logs

   # WordPress only
   npm run wp:logs

   # AspireCloud only
   docker logs -f cloudfest-aspirecloud

   # CVE Labeller only
   docker logs -f cloudfest-cve-labeller
   ```

5**Reset When Needed**
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

**Edit Code:**
- PHP: `./aspirecloud/app/`, `./aspirecloud/routes/`
- Views: `./aspirecloud/resources/views/`
- Frontend: `./aspirecloud/resources/js/`

**Rebuild Assets:**
```bash
cd aspirecloud
yarn build
# or
docker exec -w /app cloudfest-aspirecloud yarn build
```

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

### Working with CVE Labeller

**Edit Code:**
- PHP: `./cve-labeller/app/`, `./cve-labeller/routes/`
- Views: `./cve-labeller/resources/views/`

**Run Migrations:**
```bash
docker exec -w /app cloudfest-cve-labeller php artisan migrate
```

**Database Access:**
```bash
# Via Adminer: http://localhost:8080
# Select: PostgreSQL, Server: cve-labeller-db, User: postgres, Password: password

# Via command line:
docker exec -it cloudfest-cve-labeller-db psql -U postgres -d cve_labeller
```

### Working with FAIR Plugin

**Edit Code:**
- PHP: `./fair-plugin/`

**Configuration:**
- Auto-configured via `config/fair-config.php` (mu-plugin)
- Points to local AspireCloud at `http://aspirecloud:80`

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

### AspireCloud Shows "Class Not Found" Error

The Composer dependencies need to be installed:

```bash
cd aspirecloud
composer install
cd ..

# Then restart
docker-compose restart aspirecloud
```

### CVE Labeller Not Responding

```bash
# Check logs
docker logs cloudfest-cve-labeller

# Restart
docker-compose restart cve-labeller
```

### Assets Not Building

```bash
# Ensure Yarn dependencies are installed
cd aspirecloud
yarn install
yarn build
cd ..
```

### Can't Access Services

All services are accessible via port-based URLs:

- **AspireCloud**: http://localhost:8099
- **CVE Labeller**: http://localhost:8199
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
docker-compose logs -f cve-labeller
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
