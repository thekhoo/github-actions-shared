# opentofu-deploy

Deploys infrastructure using OpenTofu with an S3 state backend (`aws-management-codepipeline`) and DynamoDB locking (`aws-management-opentofu-deployment-locks`). AWS credentials must be configured before calling this action.

State key pattern: `{environment}/opentofu/{service-name}/terraform.tfstate`

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/opentofu-deploy@main
  with:
    environment: 'production'
    service-name: 'my-service'
    working-directory: 'infrastructure/tofu'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (e.g. `production`, `staging`). Used in the S3 state key |
| `service-name` | Yes | - | Service name. Used in the S3 state key |
| `working-directory` | No | `.` | Directory containing OpenTofu configuration files |
| `opentofu-version` | No | `latest` | OpenTofu version to install (e.g. `1.8.0`, `latest`) |
| `aws-region` | No | `ap-southeast-1` | AWS region for S3 backend and DynamoDB table |
| `plan-only` | No | `false` | Set to `"true"` to generate a plan without applying (useful for PRs) |
| `var-file` | No | `` | Path to a `.tfvars` file relative to `working-directory` |
| `additional-init-args` | No | `` | Extra arguments appended to `tofu init` (e.g. `-upgrade`) |

## Outputs

| Output | Description |
|--------|-------------|
| `plan-exit-code` | Exit code from `tofu plan -detailed-exitcode` (`0`=no changes, `2`=changes present) |

## What it does

1. Installs OpenTofu via `opentofu/setup-opentofu@v1`
2. **Init**: Runs `tofu init` with S3 backend config (bucket, state key, region, DynamoDB lock table)
3. **Plan**: Runs `tofu plan -detailed-exitcode -out=tfplan`, capturing whether changes exist
4. **Upload plan**: Uploads the plan file as a GitHub Actions artifact (retained 5 days)
5. **Apply**: Runs `tofu apply -auto-approve tfplan` — skipped when `plan-only=true` or there are no changes

## Requirements

- AWS credentials must be configured before calling this action (e.g. via `aws-actions/configure-aws-credentials`)
- The IAM role must have access to the S3 bucket (`aws-management-codepipeline`) and DynamoDB table (`aws-management-opentofu-deployment-locks`)
