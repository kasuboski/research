# Agent Guidelines for YouTube Knowledge Base

## Build/Lint/Test Commands

```bash
# Install dependencies
uv sync

# Run all tests
uv run pytest

# Run single test
uv run pytest tests/test_module.py::test_function

# Lint code
make lint
# or: uv run ruff check .

# Auto-fix lint issues
make lint-fix
# or: uv run ruff check --fix .

# Format code
make format
# or: uv run ruff format .

# Type check code
make typecheck
# or: uv run pyright

# Run full check (lint + typecheck + format check)
make check
```

## Code Style Guidelines

### General
- Python 3.11+ with full type annotations
- Use `@dataclass` for data models
- Line length: 100 characters (enforced by ruff)
- Double quotes for strings
- Functional programming style preferred

### Imports
- Use `isort` rules (handled by ruff)
- Standard library imports first, then third-party, then local
- Group imports with 2 blank lines between groups
- Use `from typing import` for type hints

### Naming Conventions
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Private members: prefix with underscore
- File names: `snake_case.py`

### Error Handling
- Use specific exceptions, avoid bare `except:`
- Log errors with context
- Return `None` or empty results for expected failures
- Use `sys.exit(1)` for CLI errors with rich console output

### Testing
- Use pytest with fixtures in `conftest.py`
- Mock external APIs (YouTube, Gemini)
- Test both success and failure paths
- Use descriptive test names with `test_` prefix

### Documentation
- Module docstrings for all files
- Class and function docstrings
- Use f-strings for string formatting
- Rich console for CLI output with colors/emojis