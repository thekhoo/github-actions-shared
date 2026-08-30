# python-pypi-deploy

Reusable workflow that handles the full release-to-PyPI pipeline: semantic versioning, GitHub Release creation, artifact upload, and PyPI publishing via trusted publishing (OIDC).

## Usage

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  ci:
    uses: thekhoo/github-actions-shared/.github/workflows/python-ci.yml@main
    with:
      linting-python-version: "3.13"
      pytest-python-versions: '["3.11", "3.12", "3.13"]'
      lint-directories: "src/ tests/"
      use-ruff: true
      test-directories: "tests/"

  deploy:
    needs: ci
    uses: thekhoo/github-actions-shared/.github/workflows/python-pypi-deploy.yml@main
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `python-version` | No | `3.12` | Python version for building |

## Outputs

| Output | Description |
|--------|-------------|
| `released` | `'true'` if a new version was released |
| `version` | The released version string (e.g. `1.3.0`) |
| `tag` | The git tag created (e.g. `v1.3.0`) |

## What it does

**Release job:**
1. Checks out the repository with full git history
2. Runs `python-semantic-release` to analyse conventional commits, bump version, and create a tag
3. Creates a GitHub Release with build artifacts
4. Uploads distribution artifacts for the deploy job

**Deploy job** (only runs if a release was made):
1. Downloads the distribution artifacts
2. Publishes to PyPI using [trusted publishing](https://docs.pypi.org/trusted-publishers/) (OIDC)

## Requirements

- The calling repository must use [conventional commits](https://www.conventionalcommits.org/)
- A `pyproject.toml` with `[tool.semantic_release]` configuration, including `version_toml` pointing to the version field
- A PyPI trusted publisher configured for the GitHub repository and `production` environment
- The calling workflow must run on push to main (semantic-release analyses commits since the last tag)
