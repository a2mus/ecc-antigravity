---
name: code-quality
description: Code quality review checklist and enforcement guide. KISS, DRY, YAGNI principles plus concrete code smells and their fixes. Use before marking any task complete.
metadata:
  tags: quality, review, clean-code, refactoring, checklist
  origin: ECC coding-style + patterns (adapted for Antigravity)
---

## When to Use

- Before marking any task as complete
- During code review of your own or others' code
- When refactoring existing code
- When you notice code that "feels wrong"

---

## Pre-Completion Checklist

Run through this before considering any feature done:

### Correctness
- [ ] The feature works for the happy path
- [ ] Edge cases are handled (empty input, null values, zero, negative numbers)
- [ ] Error cases are handled and produce useful messages
- [ ] Tests cover the behaviour (TDD compliant)

### Readability
- [ ] Functions and variables have descriptive names
- [ ] No single-letter variables (except loop counters `i`, `j`)
- [ ] No cryptic abbreviations
- [ ] Complex logic has a brief comment explaining WHY (not WHAT)

### Structure
- [ ] Functions are small (< 50 lines each)
- [ ] Files are focused (< 800 lines)
- [ ] No deep nesting (> 4 levels) — use early returns
- [ ] No duplicate logic (DRY rule applied)

### Safety
- [ ] No hardcoded values — use constants or config
- [ ] No mutation of shared state
- [ ] No swallowed exceptions (`except: pass`)

---

## Core Principles Applied

### KISS — Keep It Simple
```python
# WRONG — over-engineered
class LayerProcessorFactory:
    def create_processor(self, strategy_type: str) -> LayerProcessor:
        if strategy_type == "simple":
            return SimpleLayerProcessor(SimpleStrategy())
        ...

# CORRECT — solve the actual problem
def process_layer(layer: QgsVectorLayer) -> list[dict]:
    return [feature.attributes() for feature in layer.getFeatures()]
```

### DRY — Don't Repeat Yourself
```python
# WRONG — duplicated validation logic
def process_file(path):
    if not path.exists():
        raise FileNotFoundError(path)
    ...

def load_config(path):
    if not path.exists():
        raise FileNotFoundError(path)
    ...

# CORRECT — extract to shared function
def require_file(path: Path) -> Path:
    if not path.exists():
        raise FileNotFoundError(f"Required file not found: {path}")
    return path

def process_file(path): require_file(path); ...
def load_config(path): require_file(path); ...
```

### YAGNI — You Aren't Gonna Need It
```python
# WRONG — building for imagined future requirements
class DataProcessor:
    def process(self, data, strategy=None, plugin=None,
                validator=None, transformer=None):  # nobody asked for this
        ...

# CORRECT — solve TODAY's problem
def process_data(data: list[dict]) -> list[dict]:
    return [transform(item) for item in data if is_valid(item)]
```

---

## Code Smells & Fixes

### Deep Nesting → Early Returns
```python
# SMELL
def handle_request(request):
    if request:
        if request.user:
            if request.user.is_authenticated:
                if request.data:
                    return process(request.data)

# FIX
def handle_request(request):
    if not request:
        return None
    if not request.user or not request.user.is_authenticated:
        raise PermissionError("Authentication required")
    if not request.data:
        raise ValueError("Request data is required")
    return process(request.data)
```

### Magic Numbers → Named Constants
```python
# SMELL
if layer.featureCount() > 50000:
    use_chunked_processing()

# FIX
MAX_FEATURES_IN_MEMORY = 50_000

if layer.featureCount() > MAX_FEATURES_IN_MEMORY:
    use_chunked_processing()
```

### Long Function → Decompose
```python
# SMELL — a 80-line function doing 5 things
def process_and_export_layer(layer, output_path, format, crs, fields):
    # validate ...
    # transform ...
    # reproject ...
    # filter fields ...
    # export ...

# FIX — each step is its own focused function
def process_and_export_layer(layer, output_path, format, crs, fields):
    validated = validate_layer(layer)
    reprojected = reproject_to(validated, crs)
    filtered = select_fields(reprojected, fields)
    export_layer(filtered, output_path, format)
```

### Mutable Default Argument (Python Gotcha)
```python
# SMELL — the list is shared between calls!
def add_item(item, items=[]):
    items.append(item)
    return items

# FIX
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items
```

---

## Refactoring Workflow

1. **Identify the smell** — which rule above does it violate?
2. **Write a test first** — ensure behaviour is captured before changing code
3. **Make the smallest change** — one improvement at a time
4. **Run tests** — verify nothing broke
5. **Commit** — each refactor in its own commit: `refactor: extract validate_layer helper`
