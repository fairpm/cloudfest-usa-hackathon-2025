# Hello World API - Example Service

A simple PHP-based API service that demonstrates how to build and integrate services into the CloudFest USA 2025 hackathon environment.

## What This Example Demonstrates

- ✅ RESTful API with multiple endpoints
- ✅ Health check implementation (required for all services)
- ✅ Environment variable configuration
- ✅ Redis connection and caching
- ✅ AspireCloud API integration
- ✅ Structured JSON logging
- ✅ Docker multi-container setup
- ✅ Nginx + PHP-FPM configuration
- ✅ Error handling and proper HTTP status codes
- ✅ CORS headers for development

## Technology Stack

- **PHP**: 8.3-FPM (Alpine Linux)
- **Web Server**: Nginx
- **Process Manager**: Supervisor (runs PHP-FPM + Nginx)
- **Dependencies**: Redis, cURL, PostgreSQL PDO

## Quick Start

### 1. Start the Example Service

```bash
# From repository root
docker-compose -f docker-compose.example.yml up -d hello-world-api

# Follow logs
docker logs cloudfest-hello-world-api -f
```

### 2. Test the Endpoints

**Health check:**
```bash
curl http://localhost:8100/health | jq
```

**Hello endpoint:**
```bash
curl http://localhost:8100/api/hello | jq
curl http://localhost:8100/api/hello?name=CloudFest | jq
```

**Test Redis connection:**
```bash
curl http://localhost:8100/api/redis/test | jq
```

**Test AspireCloud API:**
```bash
curl http://localhost:8100/api/aspirecloud/test | jq
```

**Echo endpoint (useful for debugging):**
```bash
curl http://localhost:8100/api/echo | jq

curl -X POST http://localhost:8100/api/echo \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}' | jq
```

**Environment info:**
```bash
curl http://localhost:8100/api/env | jq
```

## API Endpoints

### `GET /` or `GET /health`
Health check endpoint (required for Docker health checks).

**Response:**
```json
{
  "status": "healthy",
  "service": "hello-world-api",
  "version": "1.0.0",
  "timestamp": "2025-11-03T12:00:00+00:00",
  "environment": {
    "php_version": "8.3.0",
    "aspirecloud_url": "http://aspirecloud:80",
    "redis_configured": true
  }
}
```

### `GET /version`
Returns service version information.

**Response:**
```json
{
  "service": "hello-world-api",
  "version": "1.0.0",
  "build": "dev",
  "environment": "development",
  "php_version": "8.3.0"
}
```

### `GET /api/hello?name=Name`
Simple hello world endpoint.

**Parameters:**
- `name` (optional): Name to greet (default: "World")

**Response:**
```json
{
  "message": "Hello, CloudFest!",
  "service": "hello-world-api",
  "timestamp": "2025-11-03T12:00:00+00:00",
  "request_id": "req_12345"
}
```

### `GET /api/redis/test`
Tests Redis connection and performs basic SET/GET operations.

**Response:**
```json
{
  "redis_connected": true,
  "host": "redis",
  "port": 6379,
  "test_key": "test:1234567890",
  "test_value": "Hello from hello-world-api",
  "retrieved_value": "Hello from hello-world-api",
  "success": true
}
```

### `GET /api/aspirecloud/test`
Tests AspireCloud API connection and retrieves plugin data.

**Response:**
```json
{
  "aspirecloud_connected": true,
  "url": "http://aspirecloud:80/plugins/info/1.1/...",
  "http_code": 200,
  "plugins_found": 1,
  "sample_plugin": {
    "name": "WooCommerce",
    "slug": "woocommerce",
    "version": "8.5.0"
  }
}
```

### `GET|POST /api/echo`
Echo endpoint that returns request details (useful for debugging).

**Response:**
```json
{
  "method": "POST",
  "uri": "/api/echo",
  "query": {},
  "body": {"test": "data"},
  "headers": {...},
  "timestamp": "2025-11-03T12:00:00+00:00"
}
```

### `GET /api/env`
Shows current environment configuration.

**Response:**
```json
{
  "service_name": "hello-world-api",
  "service_port": "8100",
  "aspirecloud_url": "http://aspirecloud:80",
  "redis_url": "redis://redis:6379",
  "log_level": "debug",
  "app_env": "development",
  "app_debug": "true"
}
```

## Configuration

### Environment Variables

See `.env.example` for all available configuration options:

```bash
SERVICE_NAME=hello-world-api      # Service identifier
SERVICE_PORT=8100                 # Internal port
ASPIRECLOUD_API_URL=http://aspirecloud:80
REDIS_URL=redis://redis:6379
LOG_LEVEL=debug                   # debug, info, warning, error
APP_ENV=local
APP_DEBUG=true
```

### Logging

The service uses structured JSON logging to stdout/stderr:

```json
{
  "timestamp": "2025-11-03T12:00:00+00:00",
  "service": "hello-world-api",
  "level": "INFO",
  "message": "Received GET request",
  "context": {
    "uri": "/api/hello"
  }
}
```

View logs:
```bash
docker logs cloudfest-hello-world-api -f
docker logs cloudfest-hello-world-api --tail 100
```

## File Structure

```
services/examples/hello-world-api/
├── Dockerfile                    # Multi-stage Docker build
├── README.md                     # This file
├── .env.example                  # Environment variables template
├── config/
│   ├── nginx.conf               # Nginx web server configuration
│   └── supervisord.conf         # Process manager config (PHP-FPM + Nginx)
└── src/
    └── index.php                # Main application (API router + handlers)
```

## Development Workflow

### 1. Modify Code
Edit `src/index.php` or add new PHP files.

### 2. Rebuild and Restart
```bash
docker-compose -f docker-compose.example.yml up -d --build hello-world-api
```

### 3. Test Changes
```bash
curl http://localhost:8100/api/hello | jq
```

### 4. View Logs
```bash
docker logs cloudfest-hello-world-api -f
```

## Testing Inter-Service Communication

### Test from Host Machine
```bash
# Using port mapping
curl http://localhost:8100/health
```

### Test from Another Container
```bash
# Using Docker network (container name)
docker exec cloudfest-aspirecloud curl http://hello-world-api:80/health

# From WordPress container
docker exec -it $(docker ps -qf 'name=.*-wordpress-1' | head -1) \
  curl http://hello-world-api:80/health
```

## Adapting This Example

### For Node.js Services
1. Replace `Dockerfile` with Node.js base image
2. Replace `src/index.php` with `src/index.js` (Express.js)
3. Add `package.json` with dependencies
4. Remove Nginx (Node.js serves HTTP directly)

### For Python Services
1. Replace with Python base image (e.g., `python:3.11-alpine`)
2. Replace `src/index.php` with `src/app.py` (Flask/FastAPI)
3. Add `requirements.txt`
4. Use Gunicorn or Uvicorn as WSGI server

### For Go Services
1. Use multi-stage build with `golang:alpine` and `alpine:latest`
2. Replace with `src/main.go`
3. Add `go.mod` for dependencies
4. Go serves HTTP directly (no Nginx needed)

## Common Tasks

### Add a New Endpoint
Edit `src/index.php` and add a new case to the router:

```php
case '/api/myendpoint':
    sendResponse([
        'message' => 'My custom endpoint',
        'data' => ['foo' => 'bar']
    ]);
    break;
```

### Add a Database
1. Add database service to `docker-compose.example.yml`
2. Add PDO connection code to `src/index.php`
3. Create schema file in `config/schema.sql`

### Add External API Integration
```php
case '/api/patchstack/check':
    $token = getenv('PATCHSTACK_API_TOKEN');
    $url = 'https://vdp-api.patchstack.com/api/...';

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $token,
            'Content-Type: application/json'
        ]
    ]);
    // ... handle response
    break;
```

## Troubleshooting

### Service won't start
```bash
# Check logs for errors
docker logs cloudfest-hello-world-api

# Rebuild without cache
docker-compose -f docker-compose.example.yml build --no-cache hello-world-api
docker-compose -f docker-compose.example.yml up -d hello-world-api
```

### Can't connect to Redis
```bash
# Verify Redis is running
docker ps | grep redis

# Test from service container
docker exec cloudfest-hello-world-api redis-cli -h redis PING
```

### Can't connect to AspireCloud
```bash
# Verify AspireCloud is running
docker ps | grep aspirecloud

# Test from service container
docker exec cloudfest-hello-world-api curl http://aspirecloud:80/health
```

### Health check failing
```bash
# Check if service is listening on port 80
docker exec cloudfest-hello-world-api netstat -tlnp | grep :80

# Test health endpoint from inside container
docker exec cloudfest-hello-world-api curl -f http://localhost/health
```

## Next Steps

1. Copy this example to your team directory: `services/{team}/{service}`
2. Modify `src/index.php` with your actual business logic
3. Update `docker-compose.example.yml` to `docker-compose.{team}.yml`
4. Change service name and port in docker-compose file
5. Add any additional dependencies (databases, queues, etc.)
6. Implement your hackathon features!

## References

- `docs/ADDING-SERVICES.md` - Detailed service integration guide
- `docs/ARCHITECTURE.md` - System architecture overview
- `docs/HACKATHON-WORKFLOW.md` - Development workflow
- `docker-compose.example.yml` - Service definition example
