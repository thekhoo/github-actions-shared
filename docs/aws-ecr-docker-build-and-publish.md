# aws-ecr-docker-build-and-publish

Builds a Docker image with buildx and pushes it to an ECR repository, tagged with the commit SHA as `commit-${commit-sha}`. Authenticates via OIDC entry role → ECR role chaining.

The companion [`aws-ecr-docker-retag`](aws-ecr-docker-retag.md) action consumes the `commit-${commit-sha}` tag produced here to apply environment-specific tags.

## Usage

```yaml
permissions:
  id-token: write
  contents: read

- uses: thekhoo/github-actions-shared/.github/actions/aws-ecr-docker-build-and-publish@main
  id: build
  with:
    commit-sha: ${{ github.sha }}
    ecr-role-arn: "arn:aws:iam::123456789012:role/ecr-push-role"
    # repository-name defaults to ${repo-name}
    # aws-region defaults to eu-west-2
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `commit-sha` | Yes | - | Git commit SHA used as the image tag (`commit-${commit-sha}`) |
| `ecr-role-arn` | Yes | - | ARN of the role with ECR push permissions |
| `repository-name` | No | `${repo-name}` | ECR repository name (must exist) |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `dockerfile-path` | No | `./Dockerfile` | Path to the Dockerfile |
| `platforms` | No | `linux/amd64` | Comma-separated list of build platforms |
| `summary-title` | No | `ECR Docker Build and Publish Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:whale:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `image-uri` | Full image URI (`<account>.dkr.ecr.<region>.amazonaws.com/<repo>:commit-<sha>`) |
| `image-tag` | The tag applied to the image (`commit-${commit-sha}`) |
| `image-digest` | sha256 digest of the pushed image |

## What it does

1. Checks out the repository
2. Authenticates via OIDC role chaining (entry role → ECR role)
3. Resolves the ECR registry (`<account>.dkr.ecr.<region>.amazonaws.com`) using `sts get-caller-identity`
4. Verifies the ECR repository exists — fails with a clear error if not
5. Logs in to ECR via `aws-actions/amazon-ecr-login`
6. Sets up Docker Buildx with GHA layer caching
7. Builds and pushes the image with tag `commit-${commit-sha}`
8. Writes a build summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The ECR repository must already exist (provision via CloudFormation/Terraform)
- The ECR role must have permissions to push to the repository (`ecr:BatchCheckLayerAvailability`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`)
