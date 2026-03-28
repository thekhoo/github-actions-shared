# deploy-infrastructure-and-docker

Orchestrates up to three deployment stages: deployment role creation, infrastructure deployment, and Docker image retagging. Each stage is independently toggleable.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/deploy-infrastructure-and-docker@main
  with:
    universe: "production"
    service-name: "my-service"
    run-deploy-deployment-role: true
    run-deploy-infrastructure: true
    run-docker-retag: true
    create-deployment-role-arn: "arn:aws:iam::123456789012:role/create-role"
    deployment-role-stack-name: "deploy-role"
    deployment-iam-role-name: "my-deploy-role"
    infrastructure-deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    infrastructure-stack-name: "my-service-infra"
    docker-registry: "ghcr.io"
    docker-username: ${{ github.actor }}
    docker-password: ${{ secrets.GITHUB_TOKEN }}
    docker-image-name: "myorg/myapp"
    docker-source-commit-sha: ${{ github.sha }}
```

## Inputs

### General

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `universe` | Yes | - | Deployment environment (e.g. `production`, `staging`) |
| `service-name` | Yes | - | Service name, used as a CloudFormation parameter |
| `aws-region` | No | `eu-west-2` | AWS region |

### Stage 1: Deployment Role

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `run-deploy-deployment-role` | Yes | `false` | Enable this stage |
| `create-deployment-role-arn` | No | - | ARN to assume for creating the deployment role |
| `deployment-role-stack-name` | No | - | CloudFormation stack name for the role |
| `deployment-iam-role-name` | No | - | IAM role name to create |

### Stage 2: Infrastructure

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `run-deploy-infrastructure` | Yes | `false` | Enable this stage |
| `infrastructure-deployment-role-arn` | No | - | ARN of the deployment role for infrastructure |
| `infrastructure-stack-name` | No | - | CloudFormation stack name for infrastructure |

### Stage 3: Docker Retag

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `run-docker-retag` | Yes | `false` | Enable this stage |
| `docker-source-commit-sha` | No | - | Source commit SHA to retag from |
| `docker-registry` | No | - | Docker registry |
| `docker-username` | No | - | Registry username |
| `docker-password` | No | - | Registry password or token |
| `docker-image-name` | No | - | Image name without registry prefix |

## What it does

**Stage 1 — Deployment Role** (if `run-deploy-deployment-role` is `true`):
Deploys `infrastructure/deployment-role.yml` as a CloudFormation stack named `{universe}-{deployment-role-stack-name}`.

**Stage 2 — Infrastructure** (if `run-deploy-infrastructure` is `true`):
Deploys `infrastructure/template.yml` as a CloudFormation stack named `{universe}-{infrastructure-stack-name}`.

**Stage 3 — Docker Retag** (if `run-docker-retag` is `true`):
Retags the Docker image from `sha-{commit-sha}` to the universe name (e.g. `production`).

Disabled stages print a skip message.

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The calling repository must have the expected CloudFormation templates at `infrastructure/deployment-role.yml` and `infrastructure/template.yml`
