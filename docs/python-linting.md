# python-linting

Runs Python linting and type checking with configurable tools. Uses `python-setup-uv` under the hood.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/python-linting@main
  with:
    python-version: "3.13"
    directories: "src/ tests/"
    use-ruff: true
    use-pyrefly: true
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `python-version` | Yes | - | Python version to install |
| `directories` | Yes | - | Space-separated list of directories to check |
| `use-ruff` | No | `false` | Enable ruff linting and format checking |
| `use-pyrefly` | No | `false` | Enable pyrefly type checking |

## What it does

1. Sets up Python with uv (via `python-setup-uv`)
2. If `use-ruff` is enabled: runs `ruff check` and `ruff format --check`
3. If `use-pyrefly` is enabled: runs `pyrefly check`

## Requirements

- A `uv.lock` file in the repository
- If using ruff: `ruff` must be in your project dependencies
- If using pyrefly: `pyrefly` must be in your project dependencies
