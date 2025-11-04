# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a hackathon development environment for CloudFest USA 2025, integrating three key technologies:
- **FAIR Package Manager** - Federated WordPress package distribution using DIDs (Decentralized Identifiers)
- **AspireCloud** - Open-source WordPress package API (CDN/mirror)
- **PatchStack** - WordPress vulnerability database API

The hackathon project goal is to build a **FAIR Software Security Assistant** that screens WordPress plugins/themes against PatchStack vulnerability data and enforces security policies for hosting providers.

## Architecture

### Multi-Container Setup

The environment combines two Docker orchestration systems:
1. **wp-env** (WordPress Environments) - Manages WordPress, MySQL, and PHP containers
2. **docker-compose** - Manages infrastructure (AspireCloud, PostgreSQL, Traefik, Redis, etc.)

These run on a shared `cloudfest-network` Docker network, connected via lifecycle hooks in `.wp-env.json`.

### Network Integration

WordPress containers are automatically connected to the `cloudfest-network` via the `afterStart` lifecycle script in `.wp-env.json`. This allows WordPress to communicate with AspireCloud and other services by hostname (e.g., `http://aspirecloud:80`, `redis`, `mailhog`).

### FAIR Plugin Configuration

The FAIR plugin is automatically cloned from GitHub if not present when running `npm run dev:start`. The plugin source lives in `plugins/fair/` (gitignored) and is loaded directly by wp-env.

The FAIR plugin is auto-configured via `config/fair-config.php`, which is mapped as a must-use plugin. This file:
- Points FAIR to the local AspireCloud instance
- Enables debug logging
- Configures package update sources

**Important**:
- Changes to `config/fair-config.php` require WordPress restart: `npm run wp:stop && npm run wp:start`
- The FAIR plugin source is in `plugins/fair/` and changes require WordPress restart
- See `docs/contributing-to-fair.md` for information on contributing changes back to FAIR

### Network Architecture

All services run on the `cloudfest-network` Docker network and are accessible via:

**From your browser (host machine):**
- Port-based URLs: `http://localhost:PORT`
- Example: `http://localhost:8099` for AspireCloud

**From WordPress container:**
- Docker container names: `http://containername:PORT`
- Example: `http://aspirecloud:80` for AspireCloud

## Essential Commands

### Primary Workflow
```bash
npm run dev:start    # One-command setup: SSL + services + database + WordPress
npm run dev:stop     # Stop all services
npm run dev:logs     # Follow all service logs
npm run dev:reset    # Complete reset (deletes ALL data)
```

### Component-Specific Commands
```bash
# WordPress only
npm run wp:start     # Start WordPress
npm run wp:stop      # Stop WordPress
npm run wp:cli -- plugin list   # WP-CLI commands

# Infrastructure only
npm run docker:up    # Start docker-compose services
npm run docker:down  # Stop docker-compose services

# Database operations
npm run db:import    # Import AspireCloud SQL snapshot

# SSL setup
npm run setup        # Re-run SSL certificate generation
```

### Development Tasks

**Access WordPress filesystem:**
```bash
docker exec -it $(docker ps -qf 'name=.*-wordpress-1') bash
cd /var/www/html/wp-content/plugins
```

**Query local AspireCloud:**
```bash
curl http://localhost:8099/plugins/info/1.1/
```

**Query PatchStack API:**
```bash
curl -X POST https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token from .env.example>" \
  -d '[{"type":"plugin","name":"woocommerce","version":"1.0.0","exists":false}]'
```

**Access PostgreSQL:**
```bash
docker exec -it cloudfest-aspirecloud-db psql -U postgres -d aspirecloud
```

## Service URLs

| Service | Browser URL | Docker Network URL | Credentials |
|---------|-------------|-------------------|-------------|
| WordPress Admin | http://localhost:8888/wp-admin | N/A | admin / password |
| AspireCloud API | http://localhost:8099 | http://aspirecloud:80 | N/A |
| Mailhog | http://localhost:8025 | http://mailhog:8025 | N/A |
| Adminer | http://localhost:8080 | N/A | postgres / password |
| Traefik Dashboard | http://localhost:8090 | N/A | N/A |

## Key Files and Their Purpose

- `.wp-env.json` - WordPress environment configuration, plugins, network lifecycle hooks
- `docker-compose.yml` - Infrastructure services (AspireCloud, Traefik, Redis, PostgreSQL)
- `config/fair-config.php` - FAIR plugin auto-configuration (mu-plugin)
- `scripts/setup-ssl.sh` - Automated mkcert installation and certificate generation
- `scripts/start-all.sh` - Main orchestration script (calls other scripts in sequence)
- `scripts/import-database.sh` - AspireCloud database import with zstd decompression
- `traefik/dynamic/tls.yml` - Traefik TLS certificate configuration
- `snapshots/aspirecloud_mini_*.sql` - AspireCloud database snapshot (24MB)

## Important Behavioral Notes

### Container Network Connectivity
- wp-env creates its own Docker network by default
- The `afterStart` lifecycle hook in `.wp-env.json` connects WordPress containers to `cloudfest-network`
- Services can be accessed from WordPress by container name: `aspirecloud`, `redis`, `mailhog`

### Database Import Behavior
The `start-all.sh` script checks if the AspireCloud database is populated before importing:
```bash
# Checks table count, imports if < 5 tables
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'
```

### Port-Based Access
All services are accessible via standard HTTP ports on localhost. No SSL/HTTPS configuration is required for local development. Docker containers communicate with each other using container names on the internal network.

### wp-env Quirks
- wp-env manages its own volumes; data persists between `wp:stop` and `wp:start`
- `wp:destroy` removes all data and volumes
- `wp:clean` resets WordPress but keeps the environment
- Changes to `.wp-env.json` require `wp:destroy && wp:start` to take effect

## Hackathon Context

### Documentation Files
- `docs/fair-pm-hackathon-guide.md` - FAIR protocol, DIDs, Ed25519 signatures, package metadata
- `docs/patchstack-hackathon-guide.md` - PatchStack vulnerability API usage
- `docs/hackathon-project-brief.md` - Project goals, team structure, deliverables

### Project Goal
Build a security screening system that:
1. Monitors FAIR repositories for new packages
2. Queries PatchStack for known vulnerabilities
3. Applies configurable security policies (approve/flag/block)
4. Provides dashboard for repository status

### Key Integration Points
- **FAIR → AspireCloud**: FAIR plugin queries AspireCloud for package metadata
- **AspireCloud → PostgreSQL**: Package data stored in PostgreSQL database
- **Plugin Development → PatchStack**: Custom plugin should query PatchStack API for vulnerabilities
- **Security Labels**: FAIR supports moderation labels (see `docs/fair-pm-hackathon-guide.md` line 29)

## Common Issues

### Can't Access Services
All services use port-based URLs accessible at `http://localhost:PORT`:
- AspireCloud: http://localhost:8099
- Mailhog: http://localhost:8025
- Adminer: http://localhost:8080
- WordPress: http://localhost:8888

Check if containers are running:
```bash
docker ps | grep cloudfest
```

### WordPress Can't Connect to AspireCloud
1. Verify docker network: `docker network inspect cloudfest-network`
2. Check WordPress is on network: `docker inspect <wordpress-container-id>`
3. Restart WordPress: `npm run wp:stop && npm run wp:start`

### Database Import Fails
Ensure zstd is installed:
- macOS: `brew install zstd`
- Linux: `sudo apt-get install zstd`

### wp-env "fatal: couldn't find remote ref latest" Error
If wp-env fails with `fatal: couldn't find remote ref latest`, ensure `.wp-env.json` uses a valid core value:
- Use `"core": null` for latest stable WordPress (recommended)
- Or use specific branch: `"core": "WordPress/WordPress#trunk"`
- Or use specific version: `"core": "WordPress/WordPress#6.4.2"`

Note: `"latest"` is not a valid git reference in the WordPress repository.

### Port Conflicts
Default ports used: 80, 443, 5432, 6379, 8025, 8080, 8090, 8099, 8888, 8889

Change ports in:
- `docker-compose.yml` (infrastructure services)
- `.wp-env.json` (WordPress ports)

## Development Patterns

### Adding a New WordPress Plugin
1. Add to `.wp-env.json` plugins array (URL or slug)
2. Run `npm run wp:destroy && npm run wp:start`
3. Or install via admin panel (persists in wp-env volumes)

### Modifying FAIR Configuration
1. Edit `config/fair-config.php`
2. Restart WordPress: `npm run wp:stop && npm run wp:start`
3. Changes take effect immediately (mu-plugin loads early)

### Testing FAIR DID Resolution
1. Query PLC directory: `curl https://plc.directory/<did>`
2. Extract serviceEndpoint from response
3. Query package metadata: `curl <serviceEndpoint>/packages/<did>`

### Adding Docker Services
1. Edit `docker-compose.yml`
2. Add service to `cloudfest-network`
3. Run `npm run docker:down && npm run docker:up`
