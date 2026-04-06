---
name: python-patterns
description: Comprehensive Python idioms, best practices, and patterns. Covers dataclasses, type hints, async, error handling, testing, and QGIS-specific patterns.
metadata:
  tags: python, patterns, idioms, qgis, typing, async
  origin: ECC python-patterns (adapted for Antigravity + QGIS)
---

## When to Use

Use whenever writing Python code to apply consistent, idiomatic patterns.
Referenced directly by GEMINI.md Python rules.

---

## Type Annotations (Required on all function signatures)

```python
from typing import Optional, Union, List, Dict, Tuple
from pathlib import Path

def process_layer(
    layer_name: str,
    output_path: Optional[Path] = None,
    crs: str = "EPSG:4326",
) -> Dict[str, int]:
    ...

# Python 3.10+ — prefer union with | instead of Union
def get_feature(fid: int | None) -> dict | None:
    ...
```

---

## Dataclasses — Prefer Frozen (Immutable)

```python
from dataclasses import dataclass, field
from typing import Sequence

@dataclass(frozen=True)
class LayerConfig:
    name: str
    crs: str = "EPSG:4326"
    fields: Sequence[str] = field(default_factory=tuple)

# NamedTuple for simple value objects
from typing import NamedTuple

class BoundingBox(NamedTuple):
    min_x: float
    min_y: float
    max_x: float
    max_y: float
```

---

## Error Handling

### Custom Exceptions
```python
class PluginError(Exception):
    """Base exception for plugin errors."""

class LayerValidationError(PluginError):
    """Raised when a layer fails validation."""

class ConfigurationError(PluginError):
    """Raised when required configuration is missing."""
```

### Specific Exception Catching
```python
# WRONG — too broad
try:
    result = process_layer(layer)
except Exception as e:
    print(f"Error: {e}")

# CORRECT — catch specific exceptions
try:
    result = process_layer(layer)
except LayerValidationError as e:
    logger.error("Layer validation failed: %s", e)
    raise
except FileNotFoundError as e:
    logger.error("Required file not found: %s", e)
    return None
```

### Early Return Over Deep Nesting
```python
# WRONG — deeply nested
def process(layer):
    if layer:
        if layer.isValid():
            if layer.featureCount() > 0:
                return do_work(layer)

# CORRECT — early returns (guard clauses)
def process(layer):
    if not layer:
        raise ValueError("Layer is required")
    if not layer.isValid():
        raise LayerValidationError(f"Layer '{layer.name()}' is invalid")
    if layer.featureCount() == 0:
        return []
    return do_work(layer)
```

---

## Context Managers

```python
from contextlib import contextmanager

@contextmanager
def editing_layer(layer):
    """Context manager for safe QGIS layer editing."""
    layer.startEditing()
    try:
        yield layer
        layer.commitChanges()
    except Exception:
        layer.rollBack()
        raise

# Usage
with editing_layer(my_layer) as layer:
    layer.addFeature(feature)
```

---

## Pathlib (Prefer over os.path)

```python
from pathlib import Path

# WRONG
import os
output = os.path.join(base_dir, "output", f"{name}.gpkg")

# CORRECT
output = Path(base_dir) / "output" / f"{name}.gpkg"

# Reading / writing
config = Path("config.json").read_text(encoding="utf-8")
output_file.write_text(result, encoding="utf-8")

# Checking existence
if not config_file.exists():
    raise FileNotFoundError(f"Config not found: {config_file}")
```

---

## Logging (Prefer over print)

```python
import logging

logger = logging.getLogger(__name__)

# WRONG
print(f"Processing layer: {layer_name}")

# CORRECT
logger.info("Processing layer: %s", layer_name)
logger.debug("Layer CRS: %s, features: %d", layer.crs().authid(), layer.featureCount())
logger.warning("Layer '%s' has no features — skipping", layer.name())
logger.error("Failed to write output: %s", error)
```

---

## QGIS-Specific Patterns

### Safe Layer Access
```python
from qgis.core import QgsVectorLayer, QgsProject

def get_layer_by_name(name: str) -> QgsVectorLayer:
    layers = QgsProject.instance().mapLayersByName(name)
    if not layers:
        raise LayerValidationError(f"No layer found with name: '{name}'")
    layer = layers[0]
    if not layer.isValid():
        raise LayerValidationError(f"Layer '{name}' is invalid")
    return layer
```

### Feature Iteration
```python
from qgis.core import QgsFeatureRequest

def get_features_filtered(layer: QgsVectorLayer, field: str, value: str):
    request = QgsFeatureRequest()
    request.setFilterExpression(f'"{field}" = \'{value}\'')
    return list(layer.getFeatures(request))
```

### QGIS Settings (Plugin Config)
```python
from qgis.core import QgsSettings

class PluginSettings:
    _PREFIX = "my_plugin"

    @classmethod
    def get(cls, key: str, default: str = "") -> str:
        return QgsSettings().value(f"{cls._PREFIX}/{key}", default)

    @classmethod
    def set(cls, key: str, value: str) -> None:
        QgsSettings().setValue(f"{cls._PREFIX}/{key}", value)
```

---

## Testing Patterns (pytest)

```python
import pytest
from pathlib import Path

# Fixtures for common test resources
@pytest.fixture
def sample_config(tmp_path: Path) -> Path:
    config = tmp_path / "config.json"
    config.write_text('{"name": "test"}')
    return config

# Parametrized tests for edge cases
@pytest.mark.parametrize("input,expected", [
    ("valid", True),
    ("", False),
    (None, False),
])
def test_validates_input(input, expected):
    assert validate(input) == expected

# Testing exceptions
def test_raises_on_missing_layer():
    with pytest.raises(LayerValidationError, match="No layer found"):
        get_layer_by_name("nonexistent_layer")
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Preferred Alternative |
|---|---|
| `except Exception:` (too broad) | Catch specific exception types |
| `os.path.join(...)` | `Path(...) / "subdir"` |
| `print(...)` for debug | `logger.debug(...)` |
| Mutable default arguments `def f(lst=[])` | `def f(lst=None): lst = lst or []` |
| String formatting via `%` or `+` | f-strings or `str.format()` |
| Nested ifs > 3 levels deep | Early returns / guard clauses |
