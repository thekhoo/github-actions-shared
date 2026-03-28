# python-pytest

Runs pytest on specified directories. Uses `python-setup-uv` under the hood.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/python-pytest@main
  with:
    python-version: "3.13"
    test-directories: "tests/ integration_tests/"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `python-version` | Yes | - | Python version to install |
| `test-directories` | No | `tests/` | Space-separated list of directories to test |

## What it does

1. Sets up Python with uv (via `python-setup-uv`)
2. Runs `uv run pytest` on the specified directories

## Requirements

- A `uv.lock` file in the repository
- `pytest` must be in your project dependencies
