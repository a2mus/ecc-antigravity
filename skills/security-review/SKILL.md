---
name: security-review
description: Security audit checklist and workflow. Run before commits, PRs, or deploying. Covers secrets detection, input validation, OWASP Top 10, and dependency scanning.
metadata:
  tags: security, audit, owasp, secrets, vulnerability
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Before ANY commit that touches auth, data handling, or API endpoints
- Before creating a pull request
- Before deploying to production
- When adding new dependencies
- Anytime something feels "off" about how data flows

## Pre-Commit Security Checklist

### Secrets & Credentials
- [ ] No API keys, passwords, or tokens in source code
- [ ] No credentials in config files committed to version control
- [ ] `.env` files are listed in `.gitignore`
- [ ] Required secrets validated at startup (not silently ignored)

### Input Validation
- [ ] All user inputs validated before processing
- [ ] File paths validated and sanitized (no path traversal)
- [ ] Integer/type bounds checked
- [ ] Schema validation used where applicable (pydantic, etc.)

### Data Handling
- [ ] SQL queries use parameterized statements (no f-string SQL)
- [ ] HTML output is sanitized (no raw user content injected)
- [ ] File uploads validated (type, size, content)
- [ ] Sensitive data not logged

### Authentication & Authorization
- [ ] Protected routes/functions check permissions
- [ ] No authorization logic on the client side only
- [ ] Session/token handling is server-side

### Error Handling
- [ ] Error messages don't expose stack traces to users
- [ ] Error messages don't leak internal paths or DB structure
- [ ] Errors are logged with context (server-side only)

## Secret Management Rules

```python
# WRONG — never do this
API_KEY = "sk-abc123..."
database_url = "postgresql://user:password@host/db"

# CORRECT — always use environment variables
import os
API_KEY = os.environ["API_KEY"]  # raises KeyError if missing — intentional
DATABASE_URL = os.environ["DATABASE_URL"]
```

For QGIS plugins, use the QGIS settings API for user configuration:
```python
from qgis.core import QgsSettings

settings = QgsSettings()
api_key = settings.value("my_plugin/api_key", "")
```

## SQL Injection Prevention

```python
# WRONG
cursor.execute(f"SELECT * FROM layers WHERE name = '{user_input}'")

# CORRECT — always use parameterized queries
cursor.execute("SELECT * FROM layers WHERE name = ?", (user_input,))
# or with psycopg2/SQLAlchemy:
cursor.execute("SELECT * FROM layers WHERE name = %s", (user_input,))
```

## Path Traversal Prevention

```python
import os
from pathlib import Path

# WRONG
file_path = base_dir + user_provided_path

# CORRECT — validate the path stays within bounds
def safe_path(base: Path, user_input: str) -> Path:
    target = (base / user_input).resolve()
    if not str(target).startswith(str(base.resolve())):
        raise ValueError("Path traversal detected")
    return target
```

## Dependency Scanning

```bash
# Python — check for known vulnerabilities
pip install safety
safety check

# Or use pip-audit
pip install pip-audit
pip-audit
```

## Incident Response Protocol

If a security issue is discovered:

1. **STOP** — do not make further commits
2. Assess the severity (CRITICAL / HIGH / MEDIUM / LOW)
3. Create a private fix branch
4. **CRITICAL issues** — fix and rotate affected secrets before ANY other work
5. Document what was exposed and for how long
6. Review the entire codebase for similar patterns

## OWASP Top 10 Quick Reference

| Risk | Check |
|------|-------|
| Injection | Parameterized queries, input validation |
| Broken Auth | Server-side session, strong token validation |
| Sensitive Data Exposure | No secrets in code, encrypted storage |
| Security Misconfiguration | No debug mode in prod, remove defaults |
| XSS | Sanitize all user-controlled HTML output |
| CSRF | Validate origin, use CSRF tokens |
| Using Vulnerable Components | `pip-audit`, `npm audit` |
| Insufficient Logging | Log auth failures, suspicious patterns |
