---
description: Test-Driven Development workflow driver. Enforces the RED/GREEN/REFACTOR cycle for a specific feature or bug fix. Adapted from ECC /tdd command.
---

# /tdd — Test-Driven Development Driver

Use this workflow for every new feature and every bug fix.
**Do NOT write production code before the test.**

## The Invariant Rule

> A test that didn't exist before you started MUST fail before the implementation.
> If a new test passes immediately, the test is wrong.

## Step 1: Define the Contract

Before touching any file, answer:
1. What should this function/behaviour DO?
2. What are its inputs and outputs?
3. What are the edge cases?
4. What error conditions should it handle?

Write this down as comments in the test file before writing test code.

## Step 2: RED — Write a Failing Test

```python
# tests/test_[feature].py

def test_[behaviour_under_test]():
    # Arrange — set up the inputs
    ...

    # Act — call the thing under test
    result = ...

    # Assert — verify the expected outcome
    assert result == expected
```

**Run the test now:**
```bash
pytest tests/test_[feature].py -v
```

The test MUST fail with the expected error (not a syntax error or import error — those mean your test file has a problem).

## Step 3: GREEN — Write Minimal Implementation

Write the MINIMUM code to make the test pass:
- Don't handle additional cases yet
- Don't optimize
- Don't add features beyond what the test demands

**Run the test:**
```bash
pytest tests/test_[feature].py -v
```

The test MUST pass. If it doesn't, fix the implementation (not the test).

## Step 4: Add Tests for Edge Cases

Repeat for:
- Empty input
- None / null values
- Boundary conditions
- Error cases

```python
@pytest.mark.parametrize("input,expected", [
    ([], []),                    # empty
    (None, pytest.raises(...)),  # null
    ([1], [1]),                  # single item
    ([1, 2, 3], [1, 2, 3]),     # normal case
])
def test_handles_all_inputs(input, expected):
    ...
```

## Step 5: REFACTOR — Clean Up

With the tests green, refactor the implementation:
- Extract helper functions if > 50 lines
- Improve naming
- Remove duplication
- Apply patterns from `python-patterns` skill

**Run all tests after each refactor step:**
```bash
pytest -v
```

## Step 6: Coverage Gate

```bash
pytest --cov=. --cov-report=term-missing

# Target: >= 80% overall, 100% on new code
```

If coverage is below 80%, identify uncovered branches and write tests for them.

## Bug Fix Workflow (TDD Applied)

When fixing a bug:
1. **Write a test that reproduces the bug** (it should fail)
2. Fix the bug (minimal change)
3. Verify the test passes
4. Verify no other tests broke

This ensures the bug can never reappear without breaking a test.

## When to Stop

The feature is done when:
- [ ] All specified behaviour has a passing test
- [ ] Edge cases and errors are handled and tested
- [ ] Coverage >= 80%
- [ ] Code passes `code-review` workflow
