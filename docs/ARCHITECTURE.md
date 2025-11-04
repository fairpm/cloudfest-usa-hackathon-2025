# Hackathon Architecture Overview

This document provides a high-level overview of the CloudFest USA 2025 hackathon development environment architecture.

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Host Machine (localhost)                      │
│                                                                       │
│  Browser Access:                                                     │
│  • http://localhost:8888  → WordPress                                │
│  • http://localhost:8099  → AspireCloud API                          │
│  • http://localhost:8XXX  → Team Services                            │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Port Mapping
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Docker Network: cloudfest-network                  │
│                                                                       │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐        │
│  │   WordPress    │  │  AspireCloud   │  │  Team Services │        │
│  │   (wp-env)     │  │    (Laravel)   │  │                │        │
│  │  :80 (internal)│  │  :80 (internal)│  │  :8XXX (custom)│        │
│  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘        │
│           │                   │                   │                  │
│           │     ┌─────────────┴─────────────┐     │                  │
│           │     │                             │     │                  │
│  ┌────────▼─────▼────┐           ┌──────────▼─────▼────┐            │
│  │   Redis Cache     │           │   PostgreSQL DB     │            │
│  │    :6379          │           │     :5432           │            │
│  └───────────────────┘           └─────────────────────┘            │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────┐        │
│  │                 Traefik Reverse Proxy                    │        │
│  │            (HTTP/HTTPS with SSL Certificates)            │        │
│  │             :80 (HTTP) :443 (HTTPS)                      │        │
│  └─────────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ External API Calls
                                    ▼
                        ┌──────────────────────┐
                        │   External Services  │
                        │  • PatchStack API    │
                        │  • FAIR Repositories │
                        └──────────────────────┘
```

## Core Infrastructure

### WordPress Environment (wp-env)
- **Purpose**: Provides WordPress installation for testing FAIR plugin integration
- **Technology**: Docker containers managed by `@wordpress/env`
- **Components**:
  - WordPress core + plugins (FAIR, WooCommerce, etc.)
  - MySQL database (internal to wp-env)
  - PHP-FPM + Nginx
- **Network**: Automatically connected to `cloudfest-network` via lifecycle hooks
- **Access**:
  - Browser: `http://localhost:8888`
  - Admin: `http://localhost:8888/wp-admin` (admin/password)
  - CLI: `npm run wp:cli -- <command>`

### AspireCloud API
- **Purpose**: WordPress package mirror/CDN (plugins, themes, core)
- **Technology**: Laravel 11 (PHP 8.3)
- **Database**: PostgreSQL 16
- **Components**:
  - REST API for package metadata
  - Plugin/theme download endpoints
  - Update API compatibility layer
- **Network**: Available as `aspirecloud:80` internally, `localhost:8099` externally
- **Key Endpoints**:
  - `GET /plugins/info/1.1/` - Plugin metadata
  - `GET /themes/info/1.1/` - Theme metadata
  - `GET /downloads/{package}` - Package downloads

### PostgreSQL Database
- **Purpose**: AspireCloud data storage
- **Version**: PostgreSQL 16 Alpine
- **Container**: `cloudfest-aspirecloud-db`
- **Access**:
  - Internal: `cloudfest-aspirecloud-db:5432`
  - External: `localhost:5432`
  - Credentials: `postgres/password`
- **Data**: Pre-populated with 24MB snapshot of WordPress.org packages

### Redis Cache
- **Purpose**: Shared cache layer for all services
- **Version**: Redis 7 Alpine
- **Container**: `cloudfest-redis`
- **Access**:
  - Internal: `redis:6379`
  - External: `localhost:6379`
- **Use Cases**:
  - AspireCloud query caching
  - Session storage
  - Pub/Sub messaging between services
  - Team service caching

### Traefik Reverse Proxy
- **Purpose**: HTTP/HTTPS routing with automatic SSL
- **Features**:
  - Automatic SSL certificate handling via mkcert
  - Service discovery via Docker labels
  - Dashboard at `http://localhost:8090`
- **Configuration**:
  - Static config: `traefik/traefik.yml`
  - Dynamic config: `traefik/dynamic/tls.yml`
  - Certificates: `traefik/certs/*.pem`

### Supporting Services
- **Mailhog**: Email testing (SMTP: `:1025`, Web UI: `localhost:8025`)
- **Adminer**: Database UI (`localhost:8080`)

## Team Service Integration

### Service Addition Pattern
Teams add services using additional docker-compose files:

```
docker-compose.yml              # Core infrastructure (AspireCloud, Redis, etc.)
docker-compose.backend.yml      # Backend team services
docker-compose.frontend.yml     # Frontend team services
docker-compose.policy.yml       # Policy team services
docker-compose.example.yml      # Example/template file
```

### Port Allocation Strategy

| Team/Purpose | Port Range | Examples |
|--------------|-----------|----------|
| Core Infrastructure | 8000-8099 | AspireCloud (8099), Adminer (8080) |
| Backend/API Team | 8100-8199 | Vuln scanner (8100), Repo monitor (8101) |
| Frontend/Dashboard Team | 8200-8299 | Dashboard UI (8200), Admin portal (8201) |
| Policy/Security Team | 8300-8399 | Policy engine (8300), Risk evaluator (8301) |
| Additional DBs | 5433-5439 | Team PostgreSQL instances |
| Additional Redis | 6380-6389 | Team Redis instances |

### Network Integration
All services **MUST**:
1. Join the `cloudfest-network` (set as `external: true`)
2. Use container names for inter-service communication
3. Implement `/health` endpoint for monitoring
4. Follow port allocation guidelines

## Communication Patterns

### 1. Synchronous Communication (HTTP REST)

**WordPress ↔ AspireCloud**
```
WordPress Plugin → http://aspirecloud:80/plugins/info/1.1/
                ← JSON package metadata
```

**Team Service → AspireCloud**
```
Vulnerability Scanner → http://aspirecloud:80/plugins/info/1.1/
                      ← Plugin metadata
```

**Team Service → PatchStack API**
```
Vulnerability Scanner → https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon
                      ← Vulnerability data
```

### 2. Asynchronous Communication (Redis Pub/Sub)

**Publisher (Example: Repository Monitor)**
```javascript
// Publish package scan event
redis.publish('channel:scans', JSON.stringify({
  event: 'package_discovered',
  package: {
    type: 'plugin',
    slug: 'woocommerce',
    version: '8.5.0'
  },
  timestamp: Date.now()
}));
```

**Subscriber (Example: Vulnerability Scanner)**
```javascript
// Subscribe to scan events
redis.subscribe('channel:scans', (message) => {
  const event = JSON.parse(message);
  if (event.event === 'package_discovered') {
    scanForVulnerabilities(event.package);
  }
});
```

### 3. Shared State (Redis Cache)

**Caching Pattern**
```javascript
// Check cache first
const cached = await redis.get(`plugin:${slug}:metadata`);
if (cached) return JSON.parse(cached);

// Fetch from AspireCloud
const metadata = await fetch(`http://aspirecloud:80/plugins/info/1.1/?action=plugin_information&slug=${slug}`);

// Cache for 1 hour
await redis.setex(`plugin:${slug}:metadata`, 3600, JSON.stringify(metadata));
```

## Data Flow Examples

### Example 1: FAIR Plugin Installation

```
1. WordPress Admin initiates plugin installation
   ↓
2. FAIR Plugin intercepts request
   ↓
3. FAIR queries AspireCloud for package metadata
   http://aspirecloud:80/plugins/info/1.1/
   ↓
4. AspireCloud queries PostgreSQL database
   ↓
5. FAIR receives package metadata + download URL
   ↓
6. FAIR downloads package from AspireCloud
   ↓
7. FAIR verifies package integrity (signatures/checksums)
   ↓
8. WordPress installs plugin
```

### Example 2: Vulnerability Scanning Workflow

```
1. Repository Monitor polls AspireCloud for new packages
   GET http://aspirecloud:80/plugins/info/1.1/
   ↓
2. Monitor publishes "new_package" event to Redis
   PUBLISH channel:packages '{"slug":"foo","version":"1.0"}'
   ↓
3. Vulnerability Scanner subscribes to Redis channel
   SUBSCRIBE channel:packages
   ↓
4. Scanner receives event and queries PatchStack API
   POST https://vdp-api.patchstack.com/api/...
   Body: [{"type":"plugin","name":"foo","version":"1.0"}]
   ↓
5. PatchStack returns vulnerability data
   ↓
6. Scanner stores results in Redis cache
   SETEX vuln:foo:1.0 3600 '{"vulns":[...]}'
   ↓
7. Scanner publishes "scan_complete" event
   PUBLISH channel:scans '{"slug":"foo","has_vulns":true}'
   ↓
8. Policy Engine receives event and applies rules
   ↓
9. Policy Engine may update FAIR repository labels
   (via FAIR repository API - to be implemented)
```

## Service Discovery

### Internal DNS (Docker Network)
Services discover each other using container names:
- `aspirecloud` → AspireCloud API
- `redis` → Redis cache
- `cloudfest-aspirecloud-db` → PostgreSQL
- `{team-service-name}` → Team services

### Service Registry (Optional)
For complex deployments, teams can use `config/service-registry.json`:

```json
{
  "services": {
    "aspirecloud": {
      "url": "http://aspirecloud:80",
      "health": "http://aspirecloud:80/health",
      "description": "WordPress package mirror API"
    },
    "vulnerability-scanner": {
      "url": "http://vuln-scanner:8100",
      "health": "http://vuln-scanner:8100/health",
      "description": "PatchStack vulnerability scanner"
    },
    "policy-engine": {
      "url": "http://policy-engine:8300",
      "health": "http://policy-engine:8300/health",
      "description": "Security policy enforcement"
    }
  }
}
```

## Security Considerations (Development Environment)

### Acceptable for Hackathon
- ✅ Hardcoded passwords in docker-compose files
- ✅ No authentication between services
- ✅ All ports exposed to host for debugging
- ✅ Debug logging enabled
- ✅ CORS enabled for all origins

### Not Acceptable (Even for Hackathon)
- ❌ Committing API tokens to Git
- ❌ Using production credentials
- ❌ Exposing services to public internet
- ❌ SQL injection vulnerabilities
- ❌ Command injection vulnerabilities

## Technology Stack Summary

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| WordPress | PHP/MySQL | Latest | Plugin testing platform |
| AspireCloud | Laravel | 11.x | Package mirror API |
| Database | PostgreSQL | 16 | Package metadata storage |
| Cache | Redis | 7 | Shared cache + pub/sub |
| Proxy | Traefik | 3.x | Reverse proxy + SSL |
| Container Runtime | Docker | 20+ | Service orchestration |
| Orchestration | docker-compose + wp-env | 3.8 | Multi-container management |

## Hackathon Project Goals

### Deliverable: FAIR Software Security Assistant

**Components to Build:**
1. **Repository Monitor** (Backend Team)
   - Poll AspireCloud for package updates
   - Track package versions
   - Publish events to Redis

2. **Vulnerability Scanner** (Backend Team)
   - Subscribe to package events
   - Query PatchStack API
   - Cache vulnerability data
   - Publish scan results

3. **Policy Engine** (Policy Team)
   - Define security policies
   - Evaluate vulnerability severity
   - Apply labels (approve/flag/block)
   - Integrate with FAIR repository

4. **Dashboard UI** (Frontend Team)
   - Visualize vulnerability data
   - Show package scan status
   - Configure policies
   - View repository health

5. **FAIR Repository Integration** (All Teams)
   - Apply moderation labels to packages
   - Support `com.atproto.label.label` records
   - Enable policy enforcement at repository level

## Scaling Considerations

### For Hackathon (2-3 teams)
- Single Docker host (laptop/workstation)
- Shared Redis instance
- Shared PostgreSQL for AspireCloud
- Simple HTTP REST + Redis pub/sub

### For Production (Future)
- Kubernetes cluster
- Dedicated Redis clusters per team
- Message queue (RabbitMQ/Kafka)
- Service mesh (Istio)
- Distributed tracing
- Monitoring + alerting

## References

- `docs/ADDING-SERVICES.md` - Step-by-step guide for adding services
- `docs/HACKATHON-WORKFLOW.md` - Daily development workflow
- `docs/fair-pm-hackathon-guide.md` - FAIR protocol documentation
- `docs/patchstack-hackathon-guide.md` - PatchStack API documentation
- `services/examples/hello-world-api/` - Example service implementation
