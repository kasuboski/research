.PHONY: lint lint-fix format typecheck check install-dev test test-cov help

help:
	@echo "Available commands:"
	@echo "  make lint        - Run Ruff linter to check for issues"
	@echo "  make lint-fix    - Run Ruff linter and auto-fix issues"
	@echo "  make format      - Format code with Ruff formatter"
	@echo "  make typecheck   - Run Pyright type checker"
	@echo "  make check       - Run linter, formatter, and type checker"
	@echo "  make test        - Run tests"
	@echo "  make test-cov    - Run tests with coverage report"
	@echo "  make install-dev - Install development dependencies"

lint:
	@echo "Running Ruff linter..."
	uv run ruff check .

lint-fix:
	@echo "Running Ruff linter with auto-fix..."
	uv run ruff check --fix .

format:
	@echo "Formatting code with Ruff..."
	uv run ruff format .

typecheck:
	@echo "Running Pyright type checker..."
	uv run pyright

check: lint typecheck
	@echo "Running Ruff formatter check..."
	uv run ruff format --check .

test:
	@echo "Running tests..."
	uv run pytest

test-cov:
	@echo "Running tests with coverage..."
	uv run pytest --cov=youtube_knowledge --cov-report=html --cov-report=term

install-dev:
	@echo "Installing development dependencies..."
	uv sync --extra dev --extra test
