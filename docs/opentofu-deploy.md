# opentofu-deploy

Deploys infrastructure using OpenTofu with an S3 state backend (`aws-management-codepipeline`) and DynamoDB locking (`aws-management-opentofu-deployment-locks`). Assumes AWS roles via OIDC role chaining (entry role → deployment role).

State key pattern: `{environment}/opentofu/{service-name}/terraform.tfstate`

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/opentofu-deploy@main
  with:
    environment: 'production'
    service-name: 'my-service'
    deployment-role-arn: 'arn:aws:iam::123456789012:role/my-deployment-role'
    working-directory: 'infrastructure/tofu'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (e.g. `production`, `staging`). Used in the S3 state key |
| `service-name` | Yes | - | Service name. Used in the S3 state key |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume for OpenTofu operations |
| `working-directory` | No | `.` | Directory containing OpenTofu configuration files |
| `opentofu-version` | No | `latest` | OpenTofu version to install (e.g. `1.8.0`, `latest`) |
| `aws-region` | No | `ap-southeast-1` | AWS region for S3 backend and DynamoDB table |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | ARN of the OIDC entry role |
| `plan-only` | No | `false` | Set to `"true"` to generate a plan without applying (useful for PRs) |
| `var-file` | No | `` | Path to a `.tfvars` file relative to `working-directory` |
| `additional-init-args` | No | `` | Extra arguments appended to `tofu init` (e.g. `-upgrade`) |

## Outputs

| Output | Description |
|--------|-------------|
| `plan-exit-code` | Exit code from `tofu plan -detailed-exitcode` (`0`=no changes, `2`=changes present) |

## What it does

1. Installs OpenTofu via `opentofu/setup-opentofu@v1`
2. **Assume OIDC entry role**: Authenticates via GitHub OIDC to assume the entry role
3. **Assume deployment role**: Chains from the entry role to the specified `deployment-role-arn`
4. **Init**: Runs `tofu init` with S3 backend config (bucket, state key, region, DynamoDB lock table)
5. **Plan**: Runs `tofu plan -detailed-exitcode -out=tfplan`, capturing whether changes exist
6. **Upload plan**: Uploads the plan file as a GitHub Actions artifact (retained 5 days)
7. **Apply**: Runs `tofu apply -auto-approve tfplan` — skipped when `plan-only=true` or there are no changes

## Requirements

- The GitHub Actions workflow must have `id-token: write` permission to authenticate via OIDC
- The deployment role must have access to the S3 bucket (`aws-management-codepipeline`) and DynamoDB table (`aws-management-opentofu-deployment-locks`)
