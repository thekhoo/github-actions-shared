# github-publish-release

Creates a GitHub Release with build artifacts for a given tag. Designed to be used after [`python-semantic-release`](python-semantic-release.md) and a successful PyPI publish.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/github-publish-release@main
  if: steps.release.outputs.released == 'true'
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    tag: ${{ steps.release.outputs.tag }}
```

See [`python-semantic-release`](python-semantic-release.md) for the full workflow pattern.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | Yes | - | GitHub token with `contents: write` permission |
| `tag` | Yes | - | The git tag to publish (e.g. `v1.3.0`) |

## What it does

1. Creates a GitHub Release for the specified tag using [python-semantic-release/publish-action](https://github.com/python-semantic-release/publish-action)
