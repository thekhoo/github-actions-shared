# python-ci

Reusable workflow that combines Python linting and pytest into a single CI pipeline. Linting runs once on a specified Python version, while tests run across a matrix of Python versions.

## Usage

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  ci:
    uses: thekhoo/github-actions-shared/.github/workflows/python-ci.yml@main
    with:
      linting-python-version: '3.13'
      pytest-python-versions: '["3.13", "3.14"]'
      lint-directories: 'src/'
      use-ruff: true
      use-pyrefly: true
      test-directories: 'tests/'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `linting-python-version` | Yes | - | Python version for linting (e.g., `3.13`, `3.14`) |
| `pytest-python-versions` | Yes | - | JSON array of Python versions for pytest matrix (e.g., `'["3.13", "3.14"]'`) |
| `lint-directories` | Yes | - | Space separated list of directories to lint |
| `use-ruff` | No | `false` | Whether to use ruff for linting |
| `use-pyrefly` | No | `false` | Whether to use pyrefly for type checking |
| `test-directories` | No | `tests/` | Space separated list of directories to run pytest on |

## What it does

**Lint job** — runs the `python-linting` action once with the specified `linting-python-version`. Executes ruff and/or pyrefly based on the `use-ruff` and `use-pyrefly` flags.

**Test job** — runs the `python-pytest` action across a matrix of Python versions specified by `pytest-python-versions`. Each version runs as a separate parallel job.

Both jobs run concurrently and are independent of each other.

## Requirements

- The calling repository must use `uv` for dependency management with a `uv.lock` file
- Linting tools (ruff, pyrefly) and pytest must be listed as dev dependencies in the project
