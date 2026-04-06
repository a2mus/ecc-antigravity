---
name: tdd-workflow
description: Test-Driven Development workflow. Enforces RED → GREEN → REFACTOR cycle with 80% coverage gate. Use for all new features and bug fixes.
metadata:
  tags: tdd, testing, pytest, quality, workflow
  origin: ECC (adapted for Antigravity)
---

## When to Use

Use PROACTIVELY for:
- Every new feature
- Every bug fix (write a failing test that reproduces it first)
- Any refactoring (tests protect existing behaviour)

## The TDD Cycle

```
┌─────────────────────────────────────────┐
│  RED   → Write a FAILING test            │
│          The test defines the contract   │
├─────────────────────────────────────────┤
│  GREEN → Write MINIMAL code to pass it  │
│          No more than what's needed     │
├─────────────────────────────────────────┤
│  REFACTOR → Clean up both code & tests  │
│             Keep tests GREEN            │
└─────────────────────────────────────────┘
         ↓
    Verify 80%+ coverage
```

## Step-by-Step Workflow

### 1. Define the Contract (before writing code)
- What should this function/module DO?
- What are the inputs and outputs?
- What are the edge cases?

### 2. Write the Test First (RED)
```python
# tests/test_my_feature.py
def test_feature_does_x_given_y():
    # Arrange
    input_data = ...

    # Act
    result = my_feature(input_data)

    # Assert
    assert result == expected_output
```

**Run it — it MUST fail.** If it passes without code, the test is wrong.

### 3. Implement Minimally (GREEN)
- Write only enough code to make the test pass
- Resist adding features not covered by tests
- Run the test — it MUST pass

### 4. Refactor (IMPROVE)
- Clean up the implementation
- Extract repeated logic
- Improve naming and structure
- **All tests must stay green**

### 5. Coverage Gate
```bash
# Python / pytest
pytest --cov=. --cov-report=term-missing

# Coverage must be >= 80%
```

## Test Structure — AAA Pattern

```python
def test_converts_document_to_markdown():
    # Arrange — set up inputs
    doc_path = Path("fixtures/sample.docx")

    # Act — call the thing under test
    result = convert_to_markdown(doc_path)

    # Assert — verify the outcome
    assert result.startswith("# ")
    assert "## Introduction" in result
```

## Naming Conventions

Use descriptive names that explain the behaviour:
```python
# GOOD
def test_returns_empty_list_when_no_layers_match():
def test_raises_value_error_when_crs_is_missing():
def test_converts_polygon_to_geojson_correctly():

# BAD
def test_convert():
def test_feature1():
```

## Troubleshooting Failing Tests

1. Read the error message carefully — use the FIRST error, not the last
2. Check test isolation — is the test polluting shared state?
3. Verify mocks are correctly configured
4. Fix the **implementation**, not the test (unless the test is genuinely wrong)
5. Never comment out or skip tests to make the suite pass

## Test Types (all required)

| Type | What it covers | Tool (Python) |
|------|----------------|---------------|
| Unit | Individual functions, utilities | `pytest` |
| Integration | API endpoints, DB, file I/O | `pytest` + fixtures |
| E2E | Critical user workflows | `pytest` + real env |

## QGIS-Specific Tips

```python
# Use pytest-qgis for QGIS layer/project fixtures
import pytest
from qgis.core import QgsVectorLayer

@pytest.fixture
def sample_layer():
    layer = QgsVectorLayer("Point?crs=EPSG:4326", "test", "memory")
    assert layer.isValid()
    return layer

def test_adds_feature_to_layer(sample_layer):
    # Arrange
    feature = QgsFeature(sample_layer.fields())

    # Act
    with edit(sample_layer):
        sample_layer.addFeature(feature)

    # Assert
    assert sample_layer.featureCount() == 1
```
