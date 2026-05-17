# aws-ecr-docker-retag

Retags an ECR image that was previously pushed by [`aws-ecr-docker-build-and-publish`](aws-ecr-docker-build-and-publish.md) under the `commit-${commit-sha}` tag. Looks up the image's digest, then applies a new tag of the form `${environment}-sha256-${short-digest}`, where `short-digest` is the first 12 hex characters of the sha256 digest.

Uses [crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane) for the tag operation — no docker daemon or pull required; the registry creates the new tag against the existing manifest.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-ecr-docker-build-and-publish@main
  with:
    commit-sha: ${{ github.sha }}
    ecr-role-arn: "arn:aws:iam::123456789012:role/ecr-push-role"

- uses: thekhoo/github-actions-shared/.github/actions/aws-ecr-docker-retag@main
  id: retag
  with:
    environment: "production"
    commit-sha: ${{ github.sha }}
    ecr-role-arn: "arn:aws:iam::123456789012:role/ecr-push-role"

# steps.retag.outputs.image-uri → e.g. 123.dkr.ecr.eu-west-2.amazonaws.com/myapp:production-sha256-abc123def456
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment, used as the prefix of the new tag |
| `commit-sha` | Yes | - | Git commit SHA of the source image (must already exist as `commit-${commit-sha}`) |
| `ecr-role-arn` | Yes | - | ARN of the role with ECR push permissions |
| `repository-name` | No | `${repo-name}` | ECR repository name |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `summary-title` | No | `ECR Docker Retag Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:label:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `image-uri` | Full image URI after retagging (`<account>.dkr.ecr.<region>.amazonaws.com/<repo>:<env>-sha256-<short>`) |
| `image-tag` | New tag applied (`${environment}-sha256-${short-digest}`) |
| `image-digest` | Full sha256 digest of the image |

## What it does

1. Authenticates via OIDC role chaining (entry role → ECR role)
2. Resolves the ECR registry using `sts get-caller-identity`
3. Logs in to ECR via `aws-actions/amazon-ecr-login` (crane reads docker's config.json for auth)
4. Installs crane via `imjasonh/setup-crane`
5. Runs `crane digest` against `commit-${commit-sha}` to fetch the full sha256 digest
6. Strips `sha256:` and takes the first 12 hex chars as the short digest
7. Applies the new tag `${environment}-sha256-${short-digest}` via `crane tag` (manifest-level operation, no image pull)
8. Writes a retag summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The image `commit-${commit-sha}` must already exist in the ECR repository (typically pushed by `aws-ecr-docker-build-and-publish`)
- The ECR role must have permissions to read manifests and put new tags (`ecr:BatchGetImage`, `ecr:PutImage`, `ecr:GetDownloadUrlForLayer`)
