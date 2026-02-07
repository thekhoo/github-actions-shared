# Github Actions Shared

A shared repository for common GitHub Actions that can be used to:

- Build and deploy Docker images
- Validate CloudFormation infrastructure
- Run Python linting and testing with `uv`
- Set up Python environments

## Available Actions

- [python-setup-uv](#python-setup-uv) - Set up Python environment with uv package manager
- [python-linting](#python-linting) - Run Python linting tools (ruff, pyrefly)
- [python-pytest](#python-pytest) - Run pytest tests
- [validate-cloudformation](#validate-cloudformation) - Validate CloudFormation templates
- [docker-build-and-publish](#docker-build-and-publish) - Build and push Docker images
- [docker-retag](#docker-retag) - Retag existing Docker images without rebuilding

---

## python-setup-uv

Set up Python environment and install dependencies using the `uv` package manager.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python-version` | Python version to use (e.g., 3.13, 3.14) | Yes | - |
| `uv-lock-file` | Path to the uv.lock file | No | `uv.lock` |

### Example

```yaml
- name: Setup Python environment
  uses: thekhoo/github-actions-shared/.github/actions/python-setup-uv@main
  with:
    python-version: '3.13'
```

---

## python-linting

Run Python linting tools with optional ruff and pyrefly support.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python-version` | Python version to use (e.g., 3.13, 3.14) | Yes | - |
| `directories` | Space-separated list of directories to check | Yes | - |
| `use-ruff` | Whether to use ruff for linting | No | `false` |
| `use-pyrefly` | Whether to use pyrefly for type checking | No | `false` |

### Example

```yaml
- name: Run Python linting
  uses: thekhoo/github-actions-shared/.github/actions/python-linting@main
  with:
    python-version: '3.13'
    directories: 'src tests'
    use-ruff: true
    use-pyrefly: true
```

---

## python-pytest

Run pytest tests on specified directories.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `python-version` | Python version to use (e.g., 3.13, 3.14) | Yes | - |
| `test-directories` | Space-separated list of directories to run pytest on | No | `tests/` |

### Example

```yaml
- name: Run tests
  uses: thekhoo/github-actions-shared/.github/actions/python-pytest@main
  with:
    python-version: '3.13'
    test-directories: 'tests/ integration_tests/'
```

---

## validate-cloudformation

Validate CloudFormation templates using cfn-lint and AWS validate-template API.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `template-paths` | Space-separated list of CloudFormation template paths | Yes | - |
| `validation-role-arn` | ARN of the deployment role for CloudFormation validation | Yes | - |
| `python-version` | Python version to use | No | `3.13` |
| `aws-region` | AWS region for validation | No | `eu-west-2` |
| `oidc-entry-role-arn` | ARN of the OIDC entry role | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` |

### Example

```yaml
- name: Validate CloudFormation templates
  uses: thekhoo/github-actions-shared/.github/actions/validate-cloudformation@main
  with:
    template-paths: 'infrastructure/template.yaml infrastructure/network.yaml'
    validation-role-arn: 'arn:aws:iam::123456789012:role/github-actions-myorg-myrepo'
    aws-region: 'us-east-1'
```

---

## docker-build-and-publish

Build and push a Docker image tagged with commit SHA. This action builds once and tags with an immutable commit reference.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `registry` | Docker registry (e.g., docker.io, ghcr.io) | Yes | - |
| `username` | Username for the Docker registry (pass via secrets) | Yes | - |
| `password` | Password or token for the Docker registry (pass via secrets) | Yes | - |
| `image-name` | Image name without registry or tags (e.g., myuser/myapp) | Yes | - |
| `commit-sha` | Git commit SHA to use as image tag | Yes | - |
| `dockerfile-path` | Path to the Dockerfile | No | `./Dockerfile` |
| `build-context` | Build context directory | No | `.` |
| `platforms` | Comma-separated list of platforms | No | `linux/amd64` |

### Outputs

| Output | Description |
|--------|-------------|
| `image-tag` | Full image tag that was built and pushed (registry/name:sha-xxx) |

### Example: Basic Build

```yaml
- name: Build and push Docker image
  id: build
  uses: thekhoo/github-actions-shared/.github/actions/docker-build-and-publish@main
  with:
    registry: docker.io
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
    image-name: myuser/myapp
    commit-sha: ${{ github.sha }}
    platforms: 'linux/amd64,linux/arm64'
```

---

## docker-retag

Retag an existing Docker image with new tags without rebuilding. Uses registry-level operations for efficiency.

### Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `registry` | Docker registry (e.g., docker.io, ghcr.io) | Yes | - |
| `username` | Username for the Docker registry (pass via secrets) | Yes | - |
| `password` | Password or token for the Docker registry (pass via secrets) | Yes | - |
| `source-image` | Full source image tag (e.g., docker.io/user/app:sha-abc123) | Yes | - |
| `target-tags` | Space-separated list of new tags (e.g., "latest v1.2.3 production") | Yes | - |
| `image-name` | Image name without registry (e.g., myuser/myapp) | Yes | - |

### Example: Tag as Production

```yaml
- name: Tag image as production
  uses: thekhoo/github-actions-shared/.github/actions/docker-retag@main
  with:
    registry: docker.io
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
    source-image: ${{ steps.build.outputs.image-tag }}
    image-name: myuser/myapp
    target-tags: 'latest production'
```

---

## Complete Workflow Examples

### Example 1: Python CI/CD Pipeline

```yaml
name: Python CI

on:
  push:
    branches: [main, develop]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run linting
        uses: thekhoo/github-actions-shared/.github/actions/python-linting@main
        with:
          python-version: '3.13'
          directories: 'src tests'
          use-ruff: true
          use-pyrefly: true

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run tests
        uses: thekhoo/github-actions-shared/.github/actions/python-pytest@main
        with:
          python-version: '3.13'
          test-directories: 'tests/'
```

### Example 2: Docker Build with Production Tagging

Build on every commit, but only tag as "production" when merged to main:

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.build.outputs.image-tag }}
    steps:
      - name: Build and push with commit SHA
        id: build
        uses: thekhoo/github-actions-shared/.github/actions/docker-build-and-publish@main
        with:
          registry: docker.io
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          image-name: myuser/myapp
          commit-sha: ${{ github.sha }}

  tag-production:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Tag as production
        uses: thekhoo/github-actions-shared/.github/actions/docker-retag@main
        with:
          registry: docker.io
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          source-image: ${{ needs.build.outputs.image-tag }}
          image-name: myuser/myapp
          target-tags: 'latest production'
```

### Example 3: Semantic Versioning for Releases

Tag with semantic versions when you push a git tag:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.build.outputs.image-tag }}
    steps:
      - name: Build and push
        id: build
        uses: thekhoo/github-actions-shared/.github/actions/docker-build-and-publish@main
        with:
          registry: docker.io
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          image-name: myuser/myapp
          commit-sha: ${{ github.sha }}

  tag-version:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Extract version
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=${VERSION}" >> $GITHUB_OUTPUT
          echo "major-minor=$(echo ${VERSION} | cut -d. -f1-2)" >> $GITHUB_OUTPUT
          echo "major=$(echo ${VERSION} | cut -d. -f1)" >> $GITHUB_OUTPUT

      - name: Tag with semantic versions
        uses: thekhoo/github-actions-shared/.github/actions/docker-retag@main
        with:
          registry: docker.io
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
          source-image: ${{ needs.build.outputs.image-tag }}
          image-name: myuser/myapp
          target-tags: '${{ steps.version.outputs.version }} ${{ steps.version.outputs.major-minor }} ${{ steps.version.outputs.major }} latest'
```

Result when pushing `v1.2.3`:
- `docker.io/myuser/myapp:sha-abc123def` (immutable build reference)
- `docker.io/myuser/myapp:1.2.3`
- `docker.io/myuser/myapp:1.2`
- `docker.io/myuser/myapp:1`
- `docker.io/myuser/myapp:latest`

### Example 4: CloudFormation Validation

```yaml
name: Validate Infrastructure

on:
  pull_request:
    paths:
      - 'infrastructure/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4

      - name: Validate CloudFormation templates
        uses: thekhoo/github-actions-shared/.github/actions/validate-cloudformation@main
        with:
          template-paths: 'infrastructure/main.yaml infrastructure/network.yaml'
          validation-role-arn: ${{ secrets.AWS_DEPLOYMENT_ROLE_ARN }}
          aws-region: 'us-east-1'
```

---

## Usage Notes

- All actions use composite action pattern for transparency and reusability
- Python actions use `uv` package manager for fast dependency management
- Docker actions use registry-level operations to avoid unnecessary image transfers
- CloudFormation validation uses OIDC role chaining for secure AWS authentication

## Contributing

When adding new actions, follow the established patterns:
- Use hyphens for action inputs (e.g., `input-name`)
- Document all inputs and outputs clearly
- Provide usage examples
- Follow the composite action structure
