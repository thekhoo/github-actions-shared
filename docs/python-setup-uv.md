# python-setup-uv

Base action that sets up a Python environment using the [uv](https://docs.astral.sh/uv/) package manager with dependency caching.

This action is used internally by `python-linting` and `python-pytest`. You only need to use it directly if you're building a custom workflow that needs a uv-managed Python environment.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/python-setup-uv@main
  with:
    python-version: "3.13"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `python-version` | Yes | - | Python version to install (e.g. `3.13`, `3.14`) |
| `uv-lock-file` | No | `uv.lock` | Path to uv.lock file for dependency resolution |

## What it does

1. Checks out the repository
2. Installs `uv` with caching enabled
3. Installs the specified Python version
4. Installs all dependencies (including dev) from the lockfile using `uv sync --frozen --dev`

## Requirements

Your repository must have a `uv.lock` file (or specify a custom path via `uv-lock-file`).
