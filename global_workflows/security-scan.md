---
description: Security scan and audit workflow. Perform a systematic security review of a codebase, module, or before a deployment. Adapted from ECC /security-scan command.
---

# /security-scan — Security Audit Workflow

Use before:
- A significant commit or pull request
- Deploying to a staging or production environment
- Sharing code externally
- Integrating a new third-party service

## Step 1: Secrets Scan

Search for hardcoded secrets in the codebase:

```bash
# Search for common patterns
grep -rn "api_key\s*=\s*['\"]" . --include="*.py"
grep -rn "password\s*=\s*['\"]" . --include="*.py"
grep -rn "token\s*=\s*['\"]" . --include="*.py"
grep -rn "secret\s*=\s*['\"]" . --include="*.py"
grep -rn "sk-\|ghp_\|glpat-" . --include="*.py"

# Check .env files are gitignored
cat .gitignore | grep -E "\.env"
```

Report any findings immediately. Rotate any exposed credentials.

## Step 2: Input Validation Audit

Review all points where external data enters the system:
- User form inputs
- File paths provided by user
- API request payloads
- Config file values
- CLI arguments

For each entry point, verify:
- [ ] Type validated
- [ ] Length/range validated
- [ ] No direct use in file operations without sanitization
- [ ] No direct use in SQL without parameterization

## Step 3: Dependency Vulnerability Check

```bash
# Python
pip install safety
safety check

# Or using pip-audit (more comprehensive)
pip install pip-audit
pip-audit

# Node.js / JavaScript
npm audit
```

Review and address HIGH and CRITICAL severity issues before proceeding.

## Step 4: Authentication & Authorization Review

For any protected resource or operation:
- [ ] Authentication is checked server-side (not just client-side)
- [ ] Authorization is checked at every access point
- [ ] No privilege escalation paths exist
- [ ] Session tokens expire and are invalidated on logout

## Step 5: Error Handling Review

Scan for insecure error handling:

```bash
# Python: Check for bare except or swallowed exceptions
grep -n "except:" . -r --include="*.py"
grep -n "except Exception:" . -r --include="*.py"

# Look for stack traces being sent to users
grep -n "traceback\|sys.exc_info" . -r --include="*.py"
```

## Step 6: Produce Security Report

```markdown
## Security Audit Report — [Date] — [Scope]

### 🔴 CRITICAL (must fix before merge/deploy)
- [Finding + location + remediation]

### 🟠 HIGH (fix soon)
- [Finding + location + remediation]

### 🟡 MEDIUM (plan to fix)
- [Finding + location + remediation]

### 🟢 LOW / Informational
- [Finding + recommendation]

### ✅ Verified Clean
- Secrets scan: PASS
- Dependency audit: X vulnerabilities (Y critical/Z high)
- Input validation: [scope covered]
```

## Incident Response

If a CRITICAL finding is discovered:
1. **STOP all other work immediately**
2. Assess: was this code ever deployed? was data exposed?
3. Fix on a private branch
4. Rotate ALL potentially exposed credentials
5. Document the incident
6. Review the full codebase for similar patterns
