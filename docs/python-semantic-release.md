# python-semantic-release

Analyses conventional commits, bumps the version in `pyproject.toml`, and creates a git tag. Does **not** create a GitHub Release or publish to PyPI — use [`github-publish-release`](github-publish-release.md) for the release step.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/python-semantic-release@main
  id: release
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}

# Publish to PyPI (only if a release was made)
- if: steps.release.outputs.released == 'true'
  run: uv build && twine upload dist/*

# Create GitHub Release (only if PyPI succeeded)
- uses: thekhoo/github-actions-shared/.github/actions/github-publish-release@main
  if: steps.release.outputs.released == 'true'
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    tag: ${{ steps.release.outputs.tag }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | Yes | - | GitHub token with `contents: write` permission |
| `python-version` | No | `3.12` | Python version for building |
| `git-committer-name` | No | `github-actions[bot]` | Name for the version bump commit |
| `git-committer-email` | No | `github-actions[bot]@users.noreply.github.com` | Email for the version bump commit |

## Outputs

| Output | Description |
|--------|-------------|
| `released` | `'true'` if a new version was released |
| `version` | The released version string (e.g. `1.3.0`) |
| `tag` | The git tag created (e.g. `v1.3.0`) |

## What it does

1. Ensures full git history is available (unshallows if needed, fetches tags)
2. Sets up Python
3. Runs [python-semantic-release](https://github.com/python-semantic-release/python-semantic-release) to analyse commits, bump version, and create a tag

## Requirements

- The repository must use [conventional commits](https://www.conventionalcommits.org/)
- A `pyproject.toml` with semantic release configuration
- The GitHub token must have `contents: write` permission

## Why is the GitHub Release a separate action?

PyPI publishing requires OIDC trusted publishing, which only works in the caller's workflow. By splitting the release creation into a separate step, you can ensure the GitHub Release is only created **after** a successful PyPI publish — no rollback needed.
