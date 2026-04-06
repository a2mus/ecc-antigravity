---
description: Feature implementation planning workflow. Creates a detailed, phased implementation plan before writing any code. Adapted from ECC /plan command.
---

# /plan — Feature Implementation Planning

Use this workflow when tackling any non-trivial feature, refactor, or architectural change.
**Do NOT write code before completing this workflow.**

## Step 1: Requirements Analysis

Read and understand the request fully. Ask yourself:
- What is the user actually trying to achieve? (desired outcome, not just the literal request)
- What are the success criteria?
- What assumptions am I making?
- Are there any external dependencies or constraints?

Before continuing, search the codebase:
```
- Does any similar feature already exist? (use grep/search)
- What patterns are already used in this project?
- What files will be affected?
```

## Step 2: Research (invoke search-first skill)

Before designing anything:
1. Does this already exist in the repo?
2. Are there libraries that solve this? (PyPI, npm)
3. Are there MCP servers for this capability?
4. See skill: `search-first` for full workflow

## Step 3: Architecture Review

- List all files that will change
- Identify dependencies between changes
- Look for reusable patterns in the existing codebase
- Identify risks (what could break?)

## Step 4: Produce the Implementation Plan

Output a plan in this format:

```markdown
# Implementation Plan: [Feature Name]

## Overview
[2-3 sentence summary of what this achieves and why]

## Requirements
- [Requirement 1]
- [Requirement 2]

## Files Changed
- [NEW] path/to/new_file.py — [purpose]
- [MODIFY] path/to/existing.py — [what changes]
- [DELETE] path/to/old.py — [why removed]

## Implementation Steps

### Phase 1: [Foundation]
1. **[Step Name]** (`path/to/file.py`)
   - Action: Specific thing to do
   - Why: Reason
   - Dependencies: None / Requires step X
   - Risk: Low / Medium / High

### Phase 2: [Core Feature]
...

## Testing Strategy
- Unit tests: [what to test]
- Integration tests: [what to test]
- Manual verification: [how to verify it works]

## Risks & Mitigations
- **Risk**: [Description]
  - Mitigation: [How to address]

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

## Step 5: User Review Gate

**Present the plan to the user before writing any code.**
Wait for explicit approval before proceeding.

If the plan is approved, create `task.md` in the artifacts directory and begin execution phase-by-phase.

## Execution Rules

Once approved:
- Work phase by phase — do not skip ahead
- Run tests after each phase
- Update task.md as you complete items
- If anything unexpected is discovered, pause and update the plan

## Sizing Guidance

| Feature Complexity | Phases |
|---|---|
| Small (1-3 files) | 1 phase — just implement |
| Medium (4-10 files) | 2 phases — foundation then feature |
| Large (10+ files) | 3-4 phases — foundation, core, polish, optimization |

Each phase must be independently testable and mergeable.
