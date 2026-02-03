# start-here

A development environment bootstrapper for the FAIR ecosystem.

## Overview

This repo provides a simple way to clone and initialize most of the FAIR projects with a single command. Rather than attempting to provide a monolithic "FAIR In A Box" Docker Compose setup, it works with each project's own build system and compose stacks.

**What this does:**
- Clones FAIR project repositories into `projects/`
- Runs each project's initialization (make, composer, etc.)
- Installs git commit hooks for automatic sign-off (required for FAIR contributions)
- Provides a Traefik reverse proxy with SSL and HTTP/3 support

**What this doesn't do:**
- Replace individual project Justfiles or Makefiles
- Provide a single unified Docker Compose for all services
- Handle every edge case of local development

## Prerequisites

- **[Just](https://github.com/casey/just)** - Command runner
  - macOS: `brew install just`
  - Linux: See [installation docs](https://github.com/casey/just#packages)
- **Git** with SSH key configured for GitHub
- **Docker** and Docker Compose
- **mkcert** - For local SSL certificates
  - macOS: `brew install mkcert`
  - Linux: See [installation docs](https://github.com/FiloSottile/mkcert#installation)
- **Composer** - PHP dependency manager (for some projects)

## Quick Start

```bash
# Clone this repository
git clone git@github.com:fairpm/start-here.git
cd start-here

# Checkout and bootstrap all FAIR projects
just start here
```

That's it. The `just start here` command will:

1. Clone all FAIR project repositories into `projects/`
2. Run each project's initialization script
3. Install git sign-off hooks

## What Gets Cloned

The following repositories are cloned into `projects/`. The "Bootstrap" column shows what `just start` runs automatically for each project:

| Project | Repository | Bootstrap |
|---------|------------|-----------|
| aspirecloud | `fairpm/aspirecloud` | `make init` |
| aspiresync | `aspirepress/aspiresync` | `make init` |
| cve-labeller | `fairpm/cve-labeller` | (needs own compose stack) |
| fair-policy-engine | `fairpm/fair-policy-engine` | (no setup required) |
| fair-plugin | `fairpm/fair-plugin` | (no setup required) |
| fair-beacon | `fairpm/fair-beacon` | `composer install` |

## Available Commands

```bash
just              # List all available commands
just checkout     # Clone all FAIR repositories (without bootstrapping)
just start        # Clone and bootstrap all FAIR projects
just start here   # Same as 'just start' (but looks neat)
```

Use `just checkout` if you only want the source code without running init/build steps. Use `just start` or `just start here` for the full setup.

## Traefik Reverse Proxy

This repo includes a Traefik setup from the AspirePress infrastructure, updated to the latest version with HTTP/3 support.

### Starting Traefik

```bash
cd traefik
bin/bootstrap   # First time: creates network, generates certs, configures Traefik
bin/up          # Start Traefik
bin/down        # Stop Traefik
```

### What Traefik Provides

- Reverse proxy for local development services
- Automatic SSL certificates via mkcert
- HTTP/3 support
- Wildcard certificates for `*.local.fair.pm` and `*.aspiredev.org`

### Integrating Your Services

Add these labels to any Docker Compose service to expose it through Traefik:

```yaml
services:
  myapp:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.local.fair.pm`)"
      - "traefik.http.routers.myapp-https.rule=Host(`myapp.local.fair.pm`)"
      - "traefik.http.routers.myapp-https.tls=true"
    networks:
      - ${TRAEFIK_PROXY_NETWORK:-traefik}

networks:
  traefik:
    name: ${TRAEFIK_PROXY_NETWORK:-traefik}
    external: true
```

## Git Sign-Off Hooks

FAIR requires all commits to include a `Signed-off-by` line. When you run `just checkout` (or `just start here`) from the start-here root directory, a git hook is automatically installed in each cloned repository. This hook adds the sign-off line to your commits automatically - no need to use `git commit -s`.

**Important:** Always run `just` commands from the start-here root directory. Running from inside a project directory will use that project's Justfile instead, and start-here's scripts won't work correctly.

## Project Structure

```
start-here/
├── justfile                 # Main command runner
├── meta/
│   └── bin/
│       ├── checkout-fair-project    # Clones a FAIR repo
│       ├── bootstrap-fair-project   # Initializes a cloned repo
│       ├── git-signoff-hook         # Auto sign-off hook
│       └── prelude.bash             # Shared utilities
├── traefik/                 # Traefik reverse proxy
│   ├── bin/                 # Traefik management scripts
│   ├── docker-compose.yml
│   └── traefik.template.yaml
└── projects/                # Cloned FAIR repositories (gitignored)
    ├── aspirecloud/
    ├── aspiresync/
    ├── cve-labeller/
    ├── fair-beacon/
    ├── fair-plugin/
    └── fair-policy-engine/
```

## Working with Individual Projects

After bootstrapping, each project lives in `projects/<name>/`. Most projects have their own build systems:

```bash
# AspireCloud
cd projects/aspirecloud
make start      # or whatever commands the project supports

# FAIR Beacon
cd projects/fair-beacon
# Run with PHP's built-in server or your preferred method
```

The goal is for each project to eventually have its own Justfile and/or compose stack.

## Troubleshooting

### SSH key issues

If you get permission denied errors or are prompted for your passphrase repeatedly:
```bash
# Add your SSH key to the agent (avoids repeated passphrase prompts)
ssh-add ~/.ssh/id_ed25519  # or your key file

# Test your GitHub SSH connection
ssh -T git@github.com
```

### mkcert not installed

Traefik requires mkcert for SSL certificates:
```bash
# macOS
brew install mkcert

# Then install the local CA
mkcert -install
```

### Project-specific issues

Each project has its own dependencies and requirements. Check the README in each project's directory under `projects/`.

## Resources

- [FAIR Protocol](https://github.com/fairpm/fair-protocol)
- [FAIR Slack](https://chat.fair.pm)
- [AspireCloud Documentation](https://docs.aspirepress.org/aspirecloud/)
