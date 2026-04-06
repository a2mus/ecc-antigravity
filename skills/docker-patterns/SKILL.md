---
name: docker-patterns
description: Docker Compose for local development, multi-service orchestration, container security, volume strategies, networking, and common troubleshooting commands.
metadata:
  tags: docker, compose, containers, networking, devops, local-dev
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Setting up Docker Compose for local development
- Designing multi-container service architectures
- Troubleshooting container networking or volume issues
- Reviewing Dockerfiles for security and size problems
- Migrating from local dev to a containerized workflow

---

## Standard Web App Stack (docker-compose.yml)

```yaml
services:
  app:
    build:
      context: .
      target: dev                     # Use dev stage of multi-stage Dockerfile
    ports:
      - "3000:3000"
    volumes:
      - .:/app                        # Bind mount for hot reload
      - /app/node_modules             # Anonymous volume — preserves container deps
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/app_dev
      - REDIS_URL=redis://redis:6379/0
      - NODE_ENV=development
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    command: npm run dev

  db:
    image: postgres:16-alpine
    ports:
      - "127.0.0.1:5432:5432"        # Only accessible from host, not the network
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: app_dev
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - redisdata:/data

  mailpit:                            # Local email testing
    image: axllent/mailpit
    ports:
      - "8025:8025"                   # Web UI
      - "1025:1025"                   # SMTP

volumes:
  pgdata:
  redisdata:
```

---

## Development vs Production Override Pattern

```yaml
# docker-compose.override.yml — auto-loaded in dev
services:
  app:
    environment:
      - DEBUG=app:*
      - LOG_LEVEL=debug
    ports:
      - "9229:9229"                   # Debugger port

# docker-compose.prod.yml — explicit for production
services:
  app:
    build:
      target: production
    restart: always
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
```

```bash
# Development (auto-loads override)
docker compose up

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Networking

### Service Discovery
Services in the same Compose network resolve by service name:
```
postgres://postgres:postgres@db:5432/app_dev
redis://redis:6379/0
http://api:3000/health
```

### Network Isolation
```yaml
services:
  frontend:
    networks: [frontend-net]

  api:
    networks: [frontend-net, backend-net]

  db:
    networks: [backend-net]           # Not reachable from frontend

networks:
  frontend-net:
  backend-net:
```

---

## Volume Strategies

```yaml
volumes:
  # Named volume — persists across restarts, managed by Docker
  pgdata:

  # Bind mount — maps host dir into container (for dev hot reload)
  # ./src:/app/src

  # Anonymous volume — preserves container content, protects from host override
  # /app/node_modules
```

```yaml
services:
  app:
    volumes:
      - .:/app                   # Source code (bind for hot reload)
      - /app/node_modules        # Protect container deps from host
      - /app/.next               # Protect Next.js build cache
  db:
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./scripts/init.sql:/docker-entrypoint-initdb.d/init.sql
```

---

## Container Security

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /app/.cache
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE            # Only if binding to ports < 1024
```

### Secret Management
```yaml
# GOOD — inject via env at runtime, never in image
services:
  app:
    env_file: .env                  # Never commit .env to Git
    environment:
      - API_KEY                     # Inherits from host environment

# BAD — never hardcode in image layer
# ENV API_KEY=sk-proj-xxxxx
```

---

## .dockerignore

```
node_modules
.git
.env
.env.*
dist
coverage
*.log
.next
.cache
docker-compose*.yml
README.md
tests/
```

---

## Common Commands

```bash
# Start services
docker compose up                     # Foreground
docker compose up -d                  # Detached (background)

# Logs
docker compose logs -f app            # Follow app logs
docker compose logs --tail=50 db      # Last 50 lines

# Execute into running container
docker compose exec app sh            # Shell into app
docker compose exec db psql -U postgres  # Connect to Postgres

# Inspect
docker compose ps                     # Running services
docker stats                          # Resource usage

# Rebuild
docker compose up --build             # Rebuild images
docker compose build --no-cache app   # Force full rebuild

# Clean up
docker compose down                   # Stop and remove containers
docker compose down -v                # Also remove volumes (⚠️ DESTRUCTIVE)
docker system prune                   # Remove unused images/containers
```

---

## Debugging Network Issues

```bash
# Check DNS resolution inside container
docker compose exec app nslookup db

# Check connectivity
docker compose exec app wget -qO- http://api:3000/health

# Inspect network
docker network ls
docker network inspect <project>_default
```

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `:latest` tags | Pin to specific versions: `postgres:16-alpine` |
| Running as root | Create non-root user (uid 1001) |
| Secrets in `docker-compose.yml` | Use `.env` file (gitignored) or Docker secrets |
| One container for all services | Separate concerns — one process per container |
| No volumes for DB data | Always mount named volumes for persistence |
| Using Docker Compose in production without orchestration | Use K8s, ECS, or Docker Swarm for production |
