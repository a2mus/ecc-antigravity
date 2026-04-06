---
description: Code review workflow. Systematic review of code you have just written. Checks quality, correctness, security, and test coverage. Adapted from ECC /code-review command.
---

# /code-review — Code Quality Review

Use this workflow after writing or modifying code, before committing.

## Step 1: Get the Diff

First, understand what changed:
```bash
git diff          # unstaged changes
git diff --staged # staged changes
git diff HEAD~1   # last commit
```

## Step 2: Correctness Check

For each changed function/method:
- [ ] Does it handle the happy path correctly?
- [ ] Does it handle empty input / null / zero / negative values?
- [ ] Does it handle errors from external calls (files, APIs, DB)?
- [ ] Are edge cases covered?

## Step 3: Code Quality Check (invoke code-quality skill)

See skill: `code-quality` for the full checklist. Key items:
- [ ] Functions < 50 lines
- [ ] Files < 800 lines
- [ ] No nesting deeper than 4 levels
- [ ] No magic numbers — use named constants
- [ ] No duplicate logic
- [ ] Descriptive names (no cryptic abbreviations)

## Step 4: Security Check

See skill: `security-review` for the full checklist. Key items:
- [ ] No hardcoded secrets
- [ ] All user inputs validated
- [ ] No SQL/path injection vectors
- [ ] Error messages don't leak internals

## Step 5: Test Coverage Check

- [ ] New code has corresponding tests
- [ ] Tests follow AAA pattern (Arrange / Act / Assert)
- [ ] Descriptive test names (explain the behaviour)
- [ ] Coverage remains >= 80%

```bash
pytest --cov=. --cov-report=term-missing
```

## Step 6: Documentation Check

- [ ] Public functions/classes have docstrings
- [ ] Complex logic has comments explaining WHY
- [ ] README updated if CLI/API surface changed
- [ ] Changelog entry added if user-facing

## Step 7: Produce Review Output

Report findings in this format:

```markdown
## Code Review: [Feature / Files Reviewed]

### ✅ Looks Good
- [What is well done]

### ⚠️ Suggestions
- **[File:Line]** — [Issue + recommended fix]

### ❌ Must Fix (blocks merge)
- **[File:Line]** — [Critical issue + fix]

### Test Coverage
- Current: X%
- Required: 80%
- Status: ✅ / ❌
```

## Severity Definitions

| Severity | Description | Action |
|---|---|---|
| ❌ Must Fix | Bug, security issue, missing test | Fix before committing |
| ⚠️ Suggestion | Code smell, readability, performance | Address if easy, note if complex |
| ✅ Looks Good | Example of good practice | Acknowledge |
