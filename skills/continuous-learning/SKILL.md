---
name: continuous-learning
description: Pattern extraction workflow. At the end of a productive session, distil reusable patterns, instincts, and lessons into persistent skill files. Prevents re-learning the same things.
metadata:
  tags: learning, patterns, knowledge, skills, memory
  origin: ECC (adapted for Antigravity)
---

## When to Use

Use at the end of any session where you:
- Discovered a non-obvious pattern or gotcha
- Solved a tricky bug with a generalizable approach
- Found a better way to structure something
- Learned a domain-specific fact (QGIS API, library quirk, etc.)

## Extraction Workflow

```
1. REFLECT on the session
   └─ What problems were solved?
   └─ What patterns emerged?
   └─ What was surprising or non-obvious?

2. DISTIL into reusable form
   └─ Is this specific to one file, or a general pattern?
   └─ Could this help in a future session?
   └─ Is it worth a new skill, or an addition to an existing one?

3. PERSIST
   ├─ New pattern → add to relevant existing skill file
   ├─ New domain knowledge → create a new skill
   └─ Project-specific → add to project's .agents/workflows/
```

## Pattern Quality Criteria

A pattern is worth capturing if it:
- [ ] Solves a recurring class of problem
- [ ] Is non-obvious (not just "use a for loop")
- [ ] Has a clear trigger (when to apply it)
- [ ] Can be expressed with a brief example

## Instinct Format

When capturing a new instinct, use this structure:

```markdown
## [Pattern Name]

**Trigger**: When should you apply this?

**Pattern**:
[Brief description or code example]

**Why**: [Why this is the right approach]

**Evidence**: [What worked / what failed without it]
```

## Example Instincts Worth Capturing

### QGIS Plugin Pattern
```markdown
## QGIS Layer Validity Check

Trigger: Whenever receiving a QgsVectorLayer from user input or plugin parameters.

Pattern:
```python
layer = iface.activeLayer()
if not layer or not layer.isValid():
    raise ValueError(f"Invalid or missing layer: {layer.name() if layer else 'None'}")
```

Why: QGIS can return None or invalid layers silently;
checking prevents cryptic downstream errors.
```

### Config Loading Pattern
```markdown
## Environment Variable Validation at Startup

Trigger: When writing any module that reads from env vars.

Pattern:
```python
REQUIRED_ENV_VARS = ["API_KEY", "DATABASE_URL"]
for var in REQUIRED_ENV_VARS:
    if not os.environ.get(var):
        raise EnvironmentError(f"Missing required env var: {var}")
```

Why: Fails fast with a clear message rather than failing
mysteriously at runtime when the var is actually used.
```

## Where to Persist

| Pattern Type | Target Location |
|---|---|
| Language idiom (Python) | `~/.gemini/skills/python-patterns/SKILL.md` |
| Security pattern | `~/.gemini/skills/security-review/SKILL.md` |
| QGIS-specific knowledge | Project-level `.agents/workflows/qgis-patterns.md` |
| New general workflow | `~/.gemini/antigravity/global_workflows/[name].md` |
| One-off project note | Project's `GEMINI.md` |

## Evolution: Promoting Instincts to Skills

When the same pattern appears 3+ times across different sessions, it deserves its own skill:

1. Create `~/.gemini/skills/[pattern-name]/SKILL.md`
2. Include: description, trigger, workflow, examples, anti-patterns
3. Reference it from this `continuous-learning` skill
