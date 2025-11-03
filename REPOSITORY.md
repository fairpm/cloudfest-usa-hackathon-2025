# Repository Structure & Clean Onboarding

This document explains what is tracked in git and what is ignored, ensuring a clean dev environment that works with a single command.

## ✅ Files Tracked in Git (Committed)

### Configuration Files
- `.wp-env.json` - WordPress environment configuration
- `docker-compose.yml` - Infrastructure services configuration
- `.env.example` - Environment template (copy to `.env`)
- `package.json` - Node.js dependencies and scripts

### Application Code
- `config/fair-config.php` - FAIR plugin auto-configuration (mu-plugin)
- `scripts/*.sh` - Setup and lifecycle scripts
- `traefik/dynamic/*.yml` - Traefik routing configuration
- `traefik/certs/.gitkeep` - Ensures SSL cert directory exists

### Documentation
- `README.md` - Main documentation
- `AGENTS.md` - Claude Code instructions
- `VERIFICATION.md` - Testing and verification guide
- `REPOSITORY.md` - This file
- `docs/` - Hackathon documentation

### Database Snapshots
- `snapshots/*.sql.zst` - AspireCloud database dumps (committed for easy setup)

## 🚫 Files Ignored (Not Committed)

### Generated/Runtime Files
- `.wp-env/` - WordPress installation (managed by wp-env)
- `node_modules/` - Node.js dependencies (installed via npm)
- `traefik/certs/*.pem` - SSL certificates (auto-generated)
- `.playwright-mcp/` - Playwright test screenshots
- `*.log` - All log files

### Environment & Secrets
- `.env` - Local environment configuration (copy from `.env.example`)
- `.env.local` - Local overrides

### Docker Artifacts
- Docker volumes (managed by Docker)
- `docker-compose.override.yml` - Local Docker customizations

### IDE & OS Files
- `.idea/`, `.vscode/` - IDE configurations
- `.DS_Store`, `Thumbs.db` - OS-specific files

## 🚀 Clean Onboarding Process

### Prerequisites
- Docker and Docker Compose
- Node.js (v18+)
- mkcert (installed automatically if missing)

### One-Command Setup
```bash
npm run dev:start
```

This single command:
1. Generates SSL certificates
2. Starts infrastructure services (AspireCloud, PostgreSQL, Redis, etc.)
3. Imports AspireCloud database snapshot
4. Starts WordPress with FAIR plugin
5. Connects WordPress to cloudfest-network
6. Installs FAIR configuration as mu-plugin
7. Verifies network connectivity

### What Happens on Fresh Clone

#### 1. Clone Repository
```bash
git clone <repository-url>
cd cloudfest-usa-2025-local-env
```

#### 2. Create `.env` File
```bash
cp .env.example .env
# Edit .env if you need custom configuration (optional)
```

#### 3. Install Dependencies & Start
```bash
npm install
npm run dev:start
```

#### 4. Access Services
- **WordPress**: http://localhost:8888/wp-admin (admin / password)
- **AspireCloud**: http://localhost:8099
- **Mailhog**: http://localhost:8025
- **Adminer**: http://localhost:8080

### Directory Structure After Setup

```
cloudfest-usa-2025-local-env/
├── .env                          # ❌ Not committed (your local config)
├── .env.example                  # ✅ Committed (template)
├── .gitignore                    # ✅ Committed
├── .wp-env/                      # ❌ Not committed (wp-env data)
├── config/
│   └── fair-config.php           # ✅ Committed
├── docker-compose.yml            # ✅ Committed
├── docs/                         # ✅ Committed
├── node_modules/                 # ❌ Not committed (npm install creates)
├── package.json                  # ✅ Committed
├── scripts/                      # ✅ Committed
│   ├── setup-ssl.sh
│   ├── start-all.sh
│   └── wp-env-after-start.sh
├── snapshots/                    # ✅ Committed
│   └── aspirecloud_mini_*.sql.zst
├── traefik/
│   ├── certs/
│   │   ├── .gitkeep              # ✅ Committed (ensures dir exists)
│   │   └── *.pem                 # ❌ Not committed (auto-generated)
│   └── dynamic/
│       └── tls.yml               # ✅ Committed
└── .playwright-mcp/              # ❌ Not committed (test artifacts)
```

## 🔧 Network Connectivity

The `wp-env-after-start.sh` script ensures WordPress containers are connected to `cloudfest-network`:

1. **Checks if network exists** - Creates if missing
2. **Disconnects containers** - Ensures clean state
3. **Reconnects containers** - Fresh connection every time
4. **Verifies connectivity** - Tests that WordPress can resolve `aspirecloud` hostname

This prevents the network disconnection issues that caused plugin installation failures.

## 📦 What Gets Installed Automatically

### On First `npm run dev:start`:
- ✅ mkcert (if not already installed)
- ✅ SSL certificates for `aspiredev.local`
- ✅ Docker containers (AspireCloud, PostgreSQL, Redis, Traefik, Adminer, Mailhog)
- ✅ AspireCloud database (imported from snapshot)
- ✅ WordPress 6.8+ with PHP 8.2
- ✅ FAIR plugin (from GitHub main branch)
- ✅ FAIR configuration as mu-plugin
- ✅ Network connectivity between WordPress and AspireCloud

### Subsequent Runs:
- Data persists in Docker volumes
- SSL certificates reused (or regenerated if expired)
- Database remains populated

## 🔄 Reset to Clean State

```bash
# Complete reset (deletes ALL data)
npm run dev:reset

# Or step-by-step:
npm run wp:destroy        # Remove WordPress
npm run docker:down       # Stop infrastructure
docker volume prune -f    # Remove volumes
rm -rf .wp-env/          # Remove wp-env cache
npm run dev:start        # Start fresh
```

## ✅ Verification

After setup, verify everything works:

```bash
# Check all services are running
docker ps

# Test AspireCloud API
curl http://localhost:8099/plugins/info/1.2/

# Check WordPress can reach AspireCloud
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) curl -s http://aspirecloud:80/plugins/info/1.2/ | head -5

# Access WordPress admin
open http://localhost:8888/wp-admin
```

## 🎯 Key Benefits of This Setup

1. **Single Command Start** - `npm run dev:start` does everything
2. **Clean Repository** - No generated files, secrets, or artifacts
3. **Reproducible** - Fresh clone works identically
4. **Network Resilience** - Automatic network connectivity verification
5. **No Manual Steps** - SSL, database, configuration all automated
6. **Cross-Platform** - Works on macOS, Linux, WSL2

## 🐛 Troubleshooting

### Plugin Installation Fails
```bash
# Verify network connectivity
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) curl -v http://aspirecloud:80/
```

### SSL Certificate Issues
```bash
# Regenerate certificates
npm run setup
```

### Database Not Populated
```bash
# Reimport database
npm run db:import
```

### mu-plugin Not Loading
```bash
# Check file exists and has correct ownership
docker exec $(docker ps -qf 'name=.*-wordpress-1' | head -1) ls -la /var/www/html/wp-content/mu-plugins/
```
