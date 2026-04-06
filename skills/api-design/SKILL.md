---
name: api-design
description: REST API design patterns — resource naming, HTTP status codes, pagination, filtering, error response format, versioning, rate limiting. Use when designing or reviewing any API endpoint.
metadata:
  tags: api, rest, http, design, typescript, python, versioning, pagination
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Designing new API endpoints
- Reviewing existing API contracts
- Adding pagination, filtering, or sorting
- Planning API versioning strategy
- Building public or partner-facing APIs

---

## URL Structure

```
# Resources are nouns, plural, lowercase, kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# Sub-resources for relationships
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# Actions that don't map to CRUD — verbs sparingly
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

```
# GOOD
/api/v1/team-members          # kebab-case for multi-word
/api/v1/orders?status=active  # query params for filtering

# BAD
/api/v1/getUsers              # verb in URL
/api/v1/user                  # singular (use plural)
/api/v1/team_members          # snake_case in URLs
```

---

## HTTP Status Codes

```
# Success
200 OK          — GET, PUT, PATCH (with response body)
201 Created     — POST (send Location header)
204 No Content  — DELETE, PUT (no body needed)

# Client Errors
400 Bad Request           — malformed JSON, type mismatch
401 Unauthorized          — missing or invalid auth token
403 Forbidden             — authenticated but not allowed
404 Not Found             — resource doesn't exist
409 Conflict              — duplicate entry, state conflict
422 Unprocessable Entity  — valid JSON but semantically wrong
429 Too Many Requests     — rate limit exceeded

# Server Errors
500 Internal Server Error — unexpected failure (never leak details)
503 Service Unavailable   — temporary overload, include Retry-After
```

---

## Standard Response Shapes

### Success (single resource)
```json
{ "data": { "id": "abc-123", "email": "alice@example.com" } }
```

### Success (collection with pagination)
```json
{
  "data": [{ "id": "abc-123" }, { "id": "def-456" }],
  "meta": { "total": 142, "page": 1, "per_page": 20, "total_pages": 8 },
  "links": {
    "self": "/api/v1/users?page=1",
    "next": "/api/v1/users?page=2",
    "last": "/api/v1/users?page=8"
  }
}
```

### Error
```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Must be a valid email", "code": "invalid_format" }
    ]
  }
}
```

---

## Pagination Strategies

| Strategy | When to Use |
|---|---|
| **Offset** (`?page=2&per_page=20`) | Admin dashboards, small datasets < 10K, search results |
| **Cursor** (`?cursor=...&limit=20`) | Feeds, infinite scroll, large/high-write datasets |

### Cursor-Based (scalable)
```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

Response:
{ "data": [...], "meta": { "has_next": true, "next_cursor": "eyJpZCI6MTQzfQ" } }
```

---

## Filtering & Sorting

```
# Equality
GET /api/v1/orders?status=active&customer_id=abc-123

# Comparison (bracket notation)
GET /api/v1/products?price[gte]=10&price[lte]=100

# Multiple values
GET /api/v1/products?category=electronics,clothing

# Sorting (prefix - for descending)
GET /api/v1/products?sort=-created_at,price
```

---

## Rate Limiting

```
Response headers:
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

429 Too Many Requests:
{ "error": { "code": "rate_limit_exceeded", "message": "Try again in 60 seconds." } }
Retry-After: 60
```

| Tier | Limit | Per |
|---|---|---|
| Anonymous | 30/min | IP |
| Authenticated | 100/min | user |
| Premium | 1000/min | API key |

---

## Versioning Strategy

```
# URL path versioning (recommended)
/api/v1/users
/api/v2/users

# Rules:
# - Start with /api/v1/ — don't version until you need to
# - Maintain at most 2 active versions (current + previous)
# - Breaking changes require a new version
# - Adding fields / optional params does NOT require a new version
# - Deprecation: 6 months notice, Sunset header, then 410 Gone
```

---

## TypeScript Example (Next.js)
```typescript
import { z } from 'zod'
import { NextRequest, NextResponse } from 'next/server'

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
})

export async function POST(req: NextRequest) {
  const body = await req.json()
  const parsed = createUserSchema.safeParse(body)

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: 'validation_error',
        message: 'Request validation failed',
        details: parsed.error.issues.map(i => ({
          field: i.path.join('.'),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 })
  }

  const user = await createUser(parsed.data)
  return NextResponse.json({ data: user }, {
    status: 201,
    headers: { Location: `/api/v1/users/${user.id}` },
  })
}
```

---

## Pre-Ship Endpoint Checklist

- [ ] URL uses plural noun, kebab-case, no verbs
- [ ] Correct HTTP method and status codes
- [ ] Input validated (Zod / Pydantic / serializer)
- [ ] Error responses follow standard shape (code + message + details)
- [ ] Pagination implemented on list endpoints
- [ ] Authentication required (or explicitly marked public)
- [ ] Authorization checked (user can only access their resources)
- [ ] Rate limiting configured
- [ ] No stack traces or internal details in error responses
- [ ] OpenAPI/Swagger spec updated
