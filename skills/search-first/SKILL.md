---
name: search-first
description: Research-before-coding workflow. Search for existing tools, libraries, and patterns before writing custom code. Use whenever adding new functionality.
metadata:
  tags: research, search, libraries, planning, workflow
  origin: ECC (adapted for Antigravity)
---

## When to Use

Use this skill BEFORE writing any new code when:
- Starting a new feature that likely has existing solutions
- Adding a dependency or integration
- About to implement a utility, helper, or abstraction
- The task starts with "add X functionality"

## Workflow

```
1. NEED ANALYSIS
   └─ Define what functionality is needed
   └─ Identify language/framework constraints

2. PARALLEL SEARCH
   ├─ PyPI / npm — existing packages
   ├─ MCP servers — check mcp_config.json
   ├─ Repo — grep/search existing codebase first
   └─ GitHub / Web — maintained OSS alternatives

3. EVALUATE CANDIDATES
   Score each on: functionality, maintenance, community,
   documentation, license, dependency weight

4. DECIDE
   ├─ Adopt as-is (exact match, well-maintained, MIT/Apache)
   ├─ Extend/Wrap (partial match, good foundation)
   ├─ Compose (combine 2-3 small packages)
   └─ Build Custom (only if nothing suitable found)

5. IMPLEMENT
   Install package / configure MCP / write minimal code
```

## Decision Matrix

| Signal | Action |
|--------|--------|
| Exact match, well-maintained, MIT/Apache | **Adopt** — install and use directly |
| Partial match, good foundation | **Extend** — install + write thin wrapper |
| Multiple weak matches | **Compose** — combine 2-3 small packages |
| Nothing suitable | **Build** — write custom, informed by research |

## Quick Pre-Code Checklist

Before writing ANY utility or new functionality, run through:

0. Does this already exist in the repo? → search with `grep`/`rg`
1. Is this a common problem? → Search PyPI / npm
2. Is there an MCP for this? → Check `~/.gemini/antigravity/mcp_config.json`
3. Is there a skill for this? → Check `~/.gemini/skills/`
4. Is there a GitHub implementation? → Search for maintained OSS

## Common Tool Lookup

### Python / QGIS
- HTTP clients → `httpx`, `requests`
- Validation → `pydantic`
- Config → `python-decouple`, `dynaconf`
- CLI → `click`, `typer`
- Geo / QGIS → Check QGIS Python API docs first
- Testing → `pytest`, `pytest-qgis`

### JavaScript / TypeScript
- HTTP clients → `ky`, `got`
- Validation → `zod`
- Testing → `jest`, `vitest`
- Linting → `eslint`, `prettier`

## Examples

**Example 1: "Add YAML config loading"**
```
Need: Load YAML config files
Search: PyPI "yaml python"
Found: PyYAML (score: 10/10)
Action: ADOPT — pip install pyyaml
Result: Zero custom code
```

**Example 2: "Add HTTP retries"**
```
Need: HTTP client with retry and timeout
Search: PyPI "httpx retry"
Found: httpx + tenacity (score: 9/10)
Action: ADOPT — use httpx with tenacity retry decorator
Result: Battle-tested, zero custom retry logic
```

## Anti-Patterns to Avoid

- ❌ Writing a utility without checking if one exists
- ❌ Not checking if an MCP server already provides the capability
- ❌ Installing a massive package for one small feature
- ❌ Wrapping a library so heavily it loses its benefits
