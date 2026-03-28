# docker-build-and-publish

Builds and publishes a Docker image to a registry with multi-platform support and GitHub Actions caching.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/docker-build-and-publish@main
  id: docker
  with:
    registry: "ghcr.io"
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
    image-name: "myorg/myapp"
    commit-sha: ${{ github.sha }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `registry` | Yes | - | Docker registry (e.g. `docker.io`, `ghcr.io`) |
| `username` | Yes | - | Registry username |
| `password` | Yes | - | Registry password or token |
| `image-name` | Yes | - | Image name without registry prefix (e.g. `myuser/myapp`) |
| `commit-sha` | Yes | - | Git commit SHA used for image tagging |
| `dockerfile-path` | No | `./Dockerfile` | Path to Dockerfile |
| `platforms` | No | `linux/amd64` | Comma-separated target platforms (e.g. `linux/amd64,linux/arm64`) |

## Outputs

| Output | Description |
|--------|-------------|
| `image-tag` | Full image tag that was pushed (e.g. `ghcr.io/myorg/myapp:sha-abc123`) |

## What it does

1. Checks out the repository
2. Sets up Docker Buildx for multi-platform builds
3. Logs in to the Docker registry
4. Builds and pushes the image tagged as `{registry}/{image-name}:sha-{commit-sha}`
5. Uses GitHub Actions cache for faster builds

## Image tagging

Images are tagged with the commit SHA: `sha-{commit-sha}`. Use [`docker-retag`](docker-retag.md) to add environment or version tags (e.g. `latest`, `production`) without rebuilding.
