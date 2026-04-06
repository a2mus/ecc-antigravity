---
description: Build error diagnosis and fix workflow. Systematic approach to resolving build, install, import, or test failures. Adapted from ECC /build-fix command.
---

# /build-fix — Build Error Resolution

Use when:
- Tests are failing unexpectedly
- Import errors or `ModuleNotFoundError`
- Package installation failures
- QGIS plugin load errors
- Type checking / linting failures

## Core Rule

> **Always read the FIRST error, not the last.**
> Error cascades hide the root cause. The first error is almost always the actual problem.

## Step 1: Capture the Full Error

Run the failing command with full output:

```bash
# Python tests
pytest -v --tb=long 2>&1

# Python imports
python -c "import my_module" 2>&1

# pip install
pip install -r requirements.txt -v 2>&1

# QGIS plugin — check QGIS Python console for tracebacks
```

**Copy the FIRST traceback block.** Ignore everything after it.

## Step 2: Classify the Error Type

| Error Pattern | Likely Cause |
|---|---|
| `ModuleNotFoundError: No module named 'X'` | Missing dependency / wrong venv |
| `ImportError: cannot import name 'X' from 'Y'` | Wrong version / circular import |
| `AttributeError: 'NoneType' has no attribute '...'` | Null pointer — missing guard |
| `TypeError: X() takes Y arguments` | API mismatch / wrong version |
| `AssertionError` in tests | Implementation disagrees with test expectation |
| `SyntaxError` | Python syntax issue in file |
| `IndentationError` | Mixed tabs/spaces |

## Step 3: Diagnose

### For Import Errors
```bash
# Verify the package is installed
pip list | grep package-name

# Verify you're in the right virtual environment
which python   # or: where python (Windows)
pip show package-name

# Check for circular imports — run the module directly
python -c "import module_a; import module_b"
```

### For Test Failures
```bash
# Run only the failing test with verbose output
pytest tests/test_specific.py::test_function_name -v --tb=long

# Check test isolation — run with fresh state
pytest tests/test_specific.py -v -p no:randomly

# Check if it's a fixture issue
pytest tests/test_specific.py -v --setup-show
```

### For QGIS Plugin Load Errors
```python
# In QGIS Python console — get the actual traceback
import traceback
try:
    import my_plugin.my_module
except Exception:
    traceback.print_exc()
```

## Step 4: Fix Incrementally

- Make **ONE change at a time**
- Run the failing command after each change
- Do NOT make multiple speculative changes simultaneously

Common fixes:
```bash
# Wrong venv / missing package
pip install missing-package

# Reinstall all dependencies
pip install -r requirements.txt --force-reinstall

# Clear Python cache (stale .pyc files)
find . -name "*.pyc" -delete
find . -name "__pycache__" -type d -exec rm -rf {} +
```

## Step 5: Verify Full Test Suite

After fixing the original failure:
```bash
pytest -v
```

Ensure you haven't introduced regressions.

## Step 6: Document the Fix

If the fix was non-obvious, add a comment:
```python
# Required: httpx must be >= 0.24 for async context manager support.
# Earlier versions lack __aenter__/__aexit__ on AsyncClient.
```

And add to `continuous-learning` skill if it's a pattern worth remembering.

## Never Do This

- ❌ Comment out the failing code to make tests pass
- ❌ Add `# noqa` or `# type: ignore` without understanding why
- ❌ Downgrade a package without checking if the root cause is elsewhere
- ❌ Make 5 changes at once and re-run — you won't know which fixed it
