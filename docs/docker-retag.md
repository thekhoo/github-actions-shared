# docker-retag

Retags an existing Docker image with new tags at the registry level, without pulling or rebuilding the image.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/docker-retag@main
  with:
    registry: "ghcr.io"
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
    image-name: "myorg/myapp"
    source-commit-sha: "abc123"
    target-tags: "latest production v1.2.3"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | Yes | - | Docker registry |
| `username` | Yes | - | Registry username |
| `password` | Yes | - | Registry password or token |
| `image-name` | Yes | - | Image name without registry prefix |
| `source-commit-sha` | Yes | - | Commit SHA of the source image to retag from |
| `target-tags` | Yes | - | Space-separated list of new tags (e.g. `"latest v1.2.3 production"`) |

## What it does

1. Logs in to the Docker registry
2. Uses `docker buildx imagetools create` to apply new tags to the existing image at the registry level

This is efficient because it operates entirely at the registry level — no image layers are downloaded or uploaded.
