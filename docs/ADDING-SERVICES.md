# Adding Services to the Hackathon Environment

This guide explains how to add your own services to the CloudFest hackathon development environment.

## Quick Start

1. Create your service directory structure
2. Write your Dockerfile and application code
3. Add service definition to a team docker-compose file
4. Start your service
5. Test connectivity

## Port Allocation

To avoid conflicts, teams should use designated port ranges:

| Team/Purpose | Port Range | Examples |
|--------------|-----------|----------|
| Core Infrastructure | 8000-8099 | AspireCloud (8099), Adminer (8080), Traefik (8090) |
| Backend/API Team | 8100-8199 | Vulnerability scanner (8100), Repository monitor (8101) |
| Frontend/Dashboard Team | 8200-8299 | Dashboard UI (8200), Admin portal (8201) |
| Policy/Security Team | 8300-8399 | Policy engine (8300), Risk evaluator (8301) |
| Additional Databases | 5433-5439 | Team-specific PostgreSQL instances |
| Additional Redis | 6380-6389 | Team-specific Redis instances |

**Check what ports are in use:**
```bash
npm run services:list
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

## Step-by-Step Guide

### 1. Create Service Directory

```bash
# Create directory for your service
mkdir -p services/examples/my-service
cd services/examples/my-service
```

**Directory structure:**
```
services/examples/my-service/
├── Dockerfile
├── .env.example
├── README.md
├── src/
│   └── (your application code)
└── config/
    └── (configuration files)
```

### 2. Write Your Dockerfile

See `docs/templates/` for Dockerfile examples for different languages:
- `Dockerfile.nodejs` - Node.js/TypeScript services
- `Dockerfile.php` - PHP services

**Example PHP Dockerfile:**
```dockerfile
FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Install dependencies
RUN apk add --no-cache nginx curl

# Copy application
COPY src/ /var/www/html/
COPY nginx.conf /etc/nginx/nginx.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8100/health || exit 1

EXPOSE 8100

CMD php-fpm & nginx -g 'daemon off;'
```

### 3. Create docker-compose File

Create a new file `docker-compose.{yourteam}.yml` or add to an existing team file.

**Example: docker-compose.backend.yml**
```yaml
version: '3.8'

services:
  my-service:
    build:
      context: ./services/examples/my-service
      dockerfile: Dockerfile
    container_name: cloudfest-my-service
    restart: unless-stopped
    environment:
      SERVICE_NAME: my-service
      SERVICE_PORT: 8100
      # Service-specific environment variables
      ASPIRECLOUD_API_URL: http://aspirecloud:80
      REDIS_URL: redis://redis:6379/1
      LOG_LEVEL: debug
    ports:
      - "8100:8100"  # Use your allocated port
    networks:
      - cloudfest-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8100/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-service.rule=Host(`my-service.aspiredev.local`)"
      - "traefik.http.routers.my-service.entrypoints=websecure"
      - "traefik.http.routers.my-service.tls=true"
      - "traefik.http.services.my-service.loadbalancer.server.port=8100"

networks:
  cloudfest-network:
    external: true  # IMPORTANT: Always use external network
```

### 4. Start Your Service

```bash
# Start core infrastructure first (if not already running)
npm run dev:start

# Start your service
docker-compose -f docker-compose.yml -f docker-compose.backend.yml up -d my-service

# Or use team script (if configured)
npm run team:backend
```

### 5. Test Connectivity

**From your host machine:**
```bash
# Test health endpoint
curl http://localhost:8100/health

# Test API endpoint
curl http://localhost:8100/api/hello
```

**From another container:**
```bash
# Use container name, not localhost
docker exec cloudfest-aspirecloud curl http://my-service:8100/health

# From WordPress
docker exec -it $(docker ps -qf 'name=.*-wordpress-1' | head -1) curl http://my-service:8100/health
```

**View logs:**
```bash
# Follow logs
docker logs cloudfest-my-service -f

# Last 100 lines
docker logs cloudfest-my-service --tail 100
```

## Required Service Endpoints

All services **MUST** implement these endpoints:

### Health Check Endpoint
```
GET /health
Response: 200 OK
{
  "status": "healthy",
  "service": "my-service",
  "version": "1.0.0",
  "timestamp": "2025-11-03T12:00:00Z"
}
```

### Version Information
```
GET /version
Response: 200 OK
{
  "service": "my-service",
  "version": "1.0.0",
  "build": "abc123",
  "environment": "development"
}
```

## Service Communication

### Accessing Other Services

**From your service (inside Docker network):**
```
http://aspirecloud:80          - AspireCloud API
http://redis:6379              - Redis cache
http://cloudfest-aspirecloud-db:5432  - AspireCloud PostgreSQL
http://other-service:8XXX      - Other team services
```

**From your browser (host machine):**
```
http://localhost:8099          - AspireCloud API
http://localhost:8100          - Your service (if exposed)
http://localhost:8200          - Dashboard UI
```

### Communication Patterns

**1. Synchronous (HTTP REST):**
```bash
# Your service calls AspireCloud
curl http://aspirecloud:80/plugins/info/1.1/

# Your service calls PatchStack
curl -X POST https://vdp-api.patchstack.com/api/sysadmin/v2/reports/vuln/hackathon \
  -H "Authorization: Bearer ${PATCHSTACK_API_TOKEN}"
```

**2. Asynchronous (Redis Pub/Sub):**
```bash
# Publisher (your service)
redis-cli -h redis PUBLISH "channel:events" '{"event":"scan_complete","plugin":"woocommerce"}'

# Subscriber (another service)
redis-cli -h redis SUBSCRIBE "channel:events"
```

## Environment Variables

### Shared Variables
These are available from the main `.env` file:

```bash
# Core services
ASPIRECLOUD_API_URL=http://aspirecloud:80
REDIS_URL=redis://redis:6379
PATCHSTACK_API_TOKEN=aapi_...
PATCHSTACK_API_URL=https://vdp-api.patchstack.com/...

# Development settings
APP_ENV=local
APP_DEBUG=true
LOG_LEVEL=debug
```

### Service-Specific Variables
Create a `.env.example` file in your service directory:

```bash
# .env.example
SERVICE_NAME=my-service
SERVICE_PORT=8100
DATABASE_URL=postgresql://postgres:password@my-service-db:5432/mydb
REDIS_DB=1
CACHE_TTL=3600
LOG_LEVEL=debug
```

## Adding a Database

If your service needs its own database:

```yaml
services:
  my-service:
    # ... (service definition)
    depends_on:
      - my-service-db

  my-service-db:
    image: postgres:16-alpine
    container_name: cloudfest-my-service-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5433:5432"  # Different port to avoid conflicts
    volumes:
      - my_service_db_data:/var/lib/postgresql/data
      - ./services/examples/my-service/schema.sql:/docker-entrypoint-initdb.d/schema.sql:ro
    networks:
      - cloudfest-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  my_service_db_data:
    driver: local
```

## Troubleshooting

### Service Won't Start

**1. Check if the port is already in use:**
```bash
docker ps | grep 8100
lsof -i :8100  # On macOS/Linux
```

**2. Check container logs:**
```bash
docker logs cloudfest-my-service
```

**3. Verify the network exists:**
```bash
docker network ls | grep cloudfest-network
npm run network:inspect
```

### Can't Connect to Other Services

**1. Verify both services are on the same network:**
```bash
docker network inspect cloudfest-network
```

**2. Use container names, not localhost:**
```bash
# ✅ Correct (from inside container)
curl http://aspirecloud:80/

# ❌ Wrong (from inside container)
curl http://localhost:8099/
```

**3. Test connectivity:**
```bash
# From your service container
docker exec cloudfest-my-service ping aspirecloud
docker exec cloudfest-my-service curl http://aspirecloud:80/
```

### Database Connection Fails

**1. Wait for database to be healthy:**
```bash
docker-compose ps
# Wait until database shows "healthy" status
```

**2. Check database credentials:**
```bash
# Verify environment variables
docker exec cloudfest-my-service env | grep DATABASE
```

**3. Test database connection:**
```bash
docker exec cloudfest-my-service-db psql -U postgres -d mydb -c "SELECT 1"
```

### Service Builds But Doesn't Run

**1. Check Dockerfile syntax:**
```bash
docker build -t test-build ./services/examples/my-service
```

**2. Run container manually:**
```bash
docker run -it --rm --network cloudfest-network --name test-service \
  -e SERVICE_PORT=8100 \
  -p 8100:8100 \
  test-build
```

**3. Check for missing dependencies:**
```bash
docker exec cloudfest-my-service ls -la /var/www/html
docker exec cloudfest-my-service which curl
```

## Best Practices

### Security (Development Environment)
- Hardcoded passwords are acceptable for hackathon
- No authentication required between services
- All services can expose ports to host for debugging

### Logging
- Use structured logging (JSON format preferred)
- Include service name, timestamp, log level
- Log to stdout/stderr (captured by Docker)

### Error Handling
- Return proper HTTP status codes (4xx, 5xx)
- Include error messages in response body
- Log errors with stack traces

### Performance
- Implement caching where appropriate (Redis)
- Use connection pooling for databases
- Set reasonable timeouts for external calls

### Docker Best Practices
- Use Alpine-based images when possible (smaller size)
- Implement multi-stage builds
- Don't run as root inside containers
- Include health checks

## Example Services

See `services/examples/hello-world-api/` for a complete working example that demonstrates:
- Basic API endpoints
- Health checks
- Environment variable configuration
- Logging
- Docker networking
- Connection to Redis and AspireCloud

## Getting Help

**Check existing services:**
```bash
docker ps
docker network inspect cloudfest-network
```

**View service logs:**
```bash
docker-compose -f docker-compose.{team}.yml logs -f
```

**Restart services:**
```bash
docker-compose -f docker-compose.{team}.yml restart my-service
```

**Rebuild after code changes:**
```bash
docker-compose -f docker-compose.{team}.yml up -d --build my-service
```

## Next Steps

1. Review `docs/ARCHITECTURE.md` for system overview
2. Check `docs/HACKATHON-WORKFLOW.md` for daily workflow
3. Look at example service in `services/examples/hello-world-api/`
4. Choose a Dockerfile template from `docs/templates/`
5. Start building your service!
