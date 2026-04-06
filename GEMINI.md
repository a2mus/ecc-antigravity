---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Coding Style

> Adapted from ECC (Everything Claude Code) common + python rules for Antigravity.

---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Coding Style

> Adapted from ECC typescript rules for Antigravity.

## Types and Interfaces

- Add parameter and return types to ALL exported functions and public class methods
- Let TypeScript infer obvious local variable types
- Use `interface` for object shapes that may be extended; `type` for unions, intersections, and utility types
- Prefer string literal unions over `enum`
- **Avoid `any`** — use `unknown` for external/untrusted input, then narrow safely

```typescript
// WRONG
function getErrorMessage(error: any) { return error.message }

// CORRECT
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) return error.message
  return 'Unexpected error'
}
```

## React Props

```typescript
interface UserCardProps {
  user: User
  onSelect: (id: string) => void
}
function UserCard({ user, onSelect }: UserCardProps) { ... }
```

## Immutability

Use spread for updates — never mutate objects in place:
```typescript
// WRONG: user.name = name
// CORRECT:
function updateUser(user: Readonly<User>, name: string): User {
  return { ...user, name }
}
```

## Input Validation

Use **Zod** for schema-based validation and infer types from the schema:
```typescript
import { z } from 'zod'
const userSchema = z.object({ email: z.string().email(), age: z.number().int().min(0) })
type UserInput = z.infer<typeof userSchema>
const validated = userSchema.parse(input)
```

## Rules
- No `console.log` in production code — use a proper logger (pino, winston)
- Async functions must use `try/catch` and narrow `error: unknown` before accessing `.message`
- See skills: `search-first`, `tdd-workflow`, `api-design`


---
paths:
  - "**/*.kt"
  - "**/*.kts"
---
# Kotlin/Android Coding Style

> Adapted from ECC for Antigravity (Android + KMP).

## Immutability
- Prefer `val` over `var`
- Use `data class` for value objects (auto-generates `copy()`, `equals()`, `hashCode()`)
- Use `sealed class` / `sealed interface` for exhaustive state modelling

## Null Safety
- Use `?` types explicitly — never suppress nullability with `!!` without a guard check
- Prefer `?.let { }` or `?: return` over `!!`

## Coroutines
- Always launch coroutines in a structured scope (`viewModelScope`, `lifecycleScope`)
- Prefer `Flow` over `LiveData` for reactive streams
- Use `Dispatchers.IO` for I/O, `Dispatchers.Default` for CPU-intensive work
- Never block the main thread

## Architecture (Android)
- Follow MVVM: ViewModel → Repository → DataSource
- Use Hilt for dependency injection
- Use `StateFlow` / `SharedFlow` for UI state

## Rules
- No `Thread.sleep()` — use `delay()` in coroutines
- See skills: `tdd-workflow`, `search-first`

## Standards

- Follow **PEP 8** conventions
- Use **type annotations** on all function signatures
- Use **black** for formatting, **isort** for import sorting, **ruff** for linting

## Immutability

Prefer immutable data structures:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class User:
    name: str
    email: str

from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float
```

## Reference

See skill: `python-patterns` for comprehensive Python idioms and patterns.

---
# Universal Coding Standards (All Files)

> These rules apply to ALL code regardless of language.

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:
- WRONG: `modify(original, field, value)` → changes original in-place
- CORRECT: `update(original, field, value)` → returns new copy with change

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## Core Principles

### KISS — Keep It Simple
- Prefer the simplest solution that actually works
- Avoid premature optimization
- Optimize for clarity over cleverness

### DRY — Don't Repeat Yourself
- Extract repeated logic into shared functions/utilities
- Avoid copy-paste implementation drift
- Introduce abstractions when repetition is real, not speculative

### YAGNI — You Aren't Gonna Need It
- Do not build features or abstractions before they are needed
- Start simple, then refactor when the pressure is real

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- 200–400 lines typical, **800 lines max**
- High cohesion, low coupling
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly messages in UI-facing code
- Log detailed error context on the server/backend side
- **Never silently swallow errors**

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available (pydantic, zod, etc.)
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)

## Naming Conventions

- Variables and functions: `snake_case` (Python) / `camelCase` (JS/TS)
- Booleans: prefer `is_`, `has_`, `should_`, or `can_` prefixes
- Classes/Types/Components: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`

## Code Quality Pre-Completion Checklist

Before marking any task complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (< 50 lines)
- [ ] Files are focused (< 800 lines)
- [ ] No deep nesting (> 4 levels) — prefer early returns
- [ ] Proper error handling at every level
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
- [ ] No magic numbers — use named constants

---
# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

Examples:
- `feat: add batch processing for document conversion`
- `fix: handle empty file list in uploader`
- `docs: update README with new CLI flags`

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (`git diff [base-branch]...HEAD`)
2. Write a comprehensive PR summary covering ALL changes
3. Include a test plan
4. Push with `-u` flag on new branches

---
# Testing Requirements

## Minimum Coverage: 80%

Three test levels required:
1. **Unit Tests** — individual functions, utilities, components
2. **Integration Tests** — API endpoints, database operations
3. **E2E Tests** — critical user flows

## TDD Workflow (MANDATORY for new features)

1. Write test first (RED — test MUST fail)
2. Write minimal implementation (GREEN — test MUST pass)
3. Refactor (IMPROVE — keep tests green)
4. Verify 80%+ coverage

## Test Structure — AAA Pattern

```python
def test_calculates_similarity_correctly():
    # Arrange
    vector1 = [1, 0, 0]
    vector2 = [0, 1, 0]

    # Act
    similarity = calculate_cosine_similarity(vector1, vector2)

    # Assert
    assert similarity == 0
```

Use descriptive test names that explain the behaviour:
- `test_returns_empty_list_when_no_results_match()`
- `test_raises_value_error_when_api_key_missing()`

---
# Security Guidelines

## Mandatory Checks Before ANY Commit

- [ ] No hardcoded secrets (API keys, passwords, tokens)
- [ ] All user inputs validated and sanitized
- [ ] SQL injection prevention (parameterized queries only)
- [ ] XSS prevention (sanitized HTML output)
- [ ] Authentication/authorization verified on protected routes
- [ ] Error messages do NOT leak sensitive data or stack traces

## Secret Management

- NEVER hardcode secrets in source code
- ALWAYS use environment variables or a secret manager
- Validate that required secrets are present at startup
- Rotate any secrets that may have been exposed

## Security Response Protocol

If a security issue is found:
1. STOP immediately
2. Invoke `security-review` skill
3. Fix CRITICAL issues before continuing
4. Rotate any exposed secrets
5. Review entire codebase for similar patterns

---
# Performance & Context Management

## Build Troubleshooting

If build fails:
1. Invoke `build-fix` workflow
2. Read error messages carefully — the cause is usually in the first error, not the last
3. Fix incrementally and verify after each fix
4. Never suppress warnings to make builds pass

## Context Window Discipline

Avoid complex multi-file tasks when context is near-full (last ~20%):
- Split large refactors into smaller PRs
- Prefer incremental, independently-verifiable steps
- Use the `plan` workflow to break down large features before coding

---
# Agent Orchestration Patterns

## When to Use Which Workflow

| Task | Invoke |
|------|--------|
| New feature or complex change | `plan` workflow first |
| Writing any new code | `tdd` workflow |
| After writing/modifying code | `code-review` skill |
| Before committing | Security checklist above |
| Build failure | `build-fix` workflow |
| Security concern | `security-review` skill |

## Parallel Task Execution

ALWAYS run independent tasks in parallel — do not serialize what can be concurrent:
- GOOD: Read 3 related files simultaneously
- BAD: Read file 1, then file 2, then file 3

## Research Before Coding

ALWAYS search before implementing:
1. Does this already exist in the repo? (grep/search)
2. Is there an existing library? (PyPI, npm)
3. Is there an MCP server for this? (check mcp_config.json)
4. Is there a skill for this? (check ~/.gemini/skills/)

See skill: `search-first` for the full workflow.
