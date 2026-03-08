# SRE Lab API

Enterprise-grade Node.js API for SRE/DevOps demonstration with observability, health checks, and production best practices.

## Features

- ✅ Health & Readiness probes (Kubernetes-ready)
- ✅ Prometheus metrics endpoint
- ✅ Structured JSON logging
- ✅ Graceful shutdown (SIGTERM handling)
- ✅ PostgreSQL database integration
- ✅ Multi-stage Docker build
- ✅ Non-root container user
- ✅ Error handling middleware

## Quick Start

### Local Development with Docker Compose

```bash
# Build and start
docker-compose up --build

# The API will be available at http://localhost:3000
```

### Test Endpoints

```bash
# Health check (liveness)
curl http://localhost:3000/health

# Readiness check (includes DB)
curl http://localhost:3000/ready

# Hello World
curl http://localhost:3000/api

# Get users
curl http://localhost:3000/api/users

# Prometheus metrics
curl http://localhost:3000/metrics

# Simulate error (for testing)
curl http://localhost:3000/api/simulate-error

# Simulate latency
curl http://localhost:3000/api/simulate-latency?ms=2000
```

## API Endpoints

| Endpoint                            | Description                 |
| ----------------------------------- | --------------------------- |
| `GET /`                             | API information             |
| `GET /health`                       | Liveness probe              |
| `GET /ready`                        | Readiness probe (checks DB) |
| `GET /metrics`                      | Prometheus metrics          |
| `GET /api`                          | Hello World                 |
| `GET /api/users`                    | List all users              |
| `GET /api/users/:id`                | Get specific user           |
| `GET /api/simulate-error`           | Trigger 500 error           |
| `GET /api/simulate-latency?ms=1000` | Delay response              |

## Environment Variables

Copy `.env.example` to `.env` and configure:

```env
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=srelab
DB_USER=postgres
DB_PASSWORD=changeme
LOG_LEVEL=info
```

## Docker Build

```bash
# Build image
docker build -t sre-lab-api:1.0.0 .

# Run container
docker run -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PASSWORD=postgres \
  sre-lab-api:1.0.0
```

## Production Best Practices Implemented

### Security

- ✅ Helmet middleware for security headers
- ✅ Non-root Docker user
- ✅ No secrets in code
- ✅ Environment-based configuration

### Observability

- ✅ Structured JSON logging (Winston)
- ✅ Prometheus metrics (RED methodology)
- ✅ Request/response logging
- ✅ Health and readiness endpoints

### Reliability

- ✅ Database connection pooling
- ✅ Graceful shutdown handlers
- ✅ Error handling middleware
- ✅ Health checks in Dockerfile

### Performance

- ✅ Multi-stage Docker build (smaller image)
- ✅ Connection pooling
- ✅ Efficient Docker layer caching

## Next Steps

1. Deploy to Kubernetes cluster
2. Configure Prometheus scraping
3. Set up Grafana dashboards
4. Implement blue-green deployment
5. Add CI/CD pipeline

## License

MIT
