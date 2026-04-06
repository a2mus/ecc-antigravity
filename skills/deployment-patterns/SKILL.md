---
name: deployment-patterns
description: CI/CD pipeline patterns, Docker multi-stage builds, deployment strategies (rolling/blue-green/canary), health checks, rollbacks, and production readiness checklists.
metadata:
  tags: devops, ci-cd, docker, github-actions, deployment, kubernetes, production
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Setting up a CI/CD pipeline from scratch
- Dockerizing an application
- Planning a deployment strategy (zero-downtime, rollbacks)
- Implementing health checks and readiness probes
- Preparing for a production release
- Reviewing infrastructure and operations readiness

---

## Deployment Strategies

### Rolling (Default)
Replace instances one at a time — requires backward-compatible changes.
```
v1 → v2 (instance 1)
v1     (instance 2, still running)
```
**Use when:** Standard deploys, compatible schema changes.

### Blue-Green
Two identical environments, atomic traffic switch.
```
Blue (v1)  ← traffic       →  Blue (v1)  idle (standby)
Green (v2) idle             →  Green (v2) ← traffic
```
**Use when:** Critical services, zero-tolerance for issues, instant rollback needed.

### Canary
Route small % of traffic first, grow if metrics look good.
```
v1: 95%  →  v1: 50%  →  v2: 100%
v2:  5%  →  v2: 50%
```
**Use when:** High-traffic services, risky changes, feature flags.

---

## Multi-Stage Dockerfiles

### Node.js
```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build && npm prune --production

FROM node:22-alpine AS runner
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001
USER appuser
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/package.json ./
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

### Python
```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir uv
COPY requirements.txt .
RUN uv pip install --system --no-cache -r requirements.txt

FROM python:3.12-slim AS runner
WORKDIR /app
RUN useradd -r -u 1001 appuser
USER appuser
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . .
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/')" || exit 1
CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4"]
```

### Dockerfile Best Practices
```
✅ Use specific version tags (node:22-alpine, not node:latest)
✅ Multi-stage builds — minimize production image size
✅ Run as non-root user (uid 1001)
✅ COPY dependency files BEFORE source (layer caching)
✅ Add HEALTHCHECK instruction
✅ Use .dockerignore (exclude node_modules, .git, tests, .env)

❌ Running as root
❌ :latest tags
❌ Storing secrets in image layers (use env vars)
❌ One giant container with all services
```

---

## GitHub Actions CI/CD Pipeline

```yaml
name: CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test -- --coverage
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Deploy
        run: |
          # Railway: railway up
          # Vercel:  vercel --prod
          # K8s:     kubectl set image deployment/app app=ghcr.io/${{ github.repository }}:${{ github.sha }}
          echo "Deploying ${{ github.sha }}"
```

### Pipeline Stage Map
```
PR opened:
  lint → typecheck → unit tests → integration tests → preview deploy

Merged to main:
  lint → typecheck → unit tests → integration tests
  → build image → deploy staging → smoke tests → deploy production
```

---

## Health Check Endpoints

```typescript
// Simple — for liveness
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }))

// Detailed — for readiness / monitoring
app.get('/health/detailed', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkRedis(),
  }
  const allHealthy = Object.values(checks).every(c => c.status === 'ok')
  res.status(allHealthy ? 200 : 503).json({
    status: allHealthy ? 'ok' : 'degraded',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION,
    checks,
  })
})
```

### Kubernetes Probes
```yaml
livenessProbe:
  httpGet: { path: /health, port: 3000 }
  initialDelaySeconds: 10
  periodSeconds: 30
  failureThreshold: 3

readinessProbe:
  httpGet: { path: /health, port: 3000 }
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 2
```

---

## Environment Configuration (12-Factor)

```typescript
import { z } from 'zod'

// Validate ALL required env vars at startup — fail fast
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'staging', 'production']),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
})

export const env = envSchema.parse(process.env)
```

---

## Rollback Strategy

```bash
# Kubernetes
kubectl rollout undo deployment/app

# Vercel
vercel rollback

# Railway
railway up --commit <previous-sha>

# Database (if reversible)
npx prisma migrate resolve --rolled-back <migration-name>
```

### Rollback Checklist
- [ ] Previous image/artifact is tagged and available
- [ ] Database migrations are backward-compatible
- [ ] Feature flags can disable new features without redeploy
- [ ] Monitoring alerts configured for error rate spikes
- [ ] Rollback procedure tested in staging

---

## Production Readiness Checklist

### Application
- [ ] All tests pass (unit, integration, E2E)
- [ ] No hardcoded secrets — all via env vars
- [ ] Health check endpoint returns meaningful status
- [ ] Logging is structured JSON, no PII logged

### Infrastructure
- [ ] Docker image builds reproducibly (pinned versions)
- [ ] Environment variables documented + validated at startup
- [ ] Resource limits set (CPU, memory)
- [ ] SSL/TLS enabled on all endpoints

### Security
- [ ] Dependencies scanned (`npm audit`, `pip-audit`)
- [ ] CORS configured for allowed origins only
- [ ] Rate limiting on all public endpoints
- [ ] Security headers set (CSP, HSTS, X-Frame-Options)

### Operations
- [ ] Rollback plan documented and tested
- [ ] Uptime monitoring on health endpoint
- [ ] Log aggregation and alerting configured
- [ ] On-call rotation defined
