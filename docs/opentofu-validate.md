# opentofu-validate

Validates OpenTofu configuration files: formatting and configuration correctness. Runs without a real backend, so it is safe for CI and lint pipelines on every push or pull request. The action needs AWS credentials only when the configuration uses modules from the private `terraform-modules` repository.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/opentofu-validate@main
  with:
    working-directory: 'infrastructure/tofu'
```

Usage with private modules:

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/opentofu-validate@main
  with:
    working-directory: 'infrastructure/tofu'
    deployment-role-arn: 'arn:aws:iam::020844256789:role/github-actions-create-deployment-role'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `working-directory` | No | `.` | Directory containing OpenTofu configuration files |
| `opentofu-version` | No | `latest` | OpenTofu version to install (e.g. `1.8.0`, `latest`) |
| `deployment-role-arn` | No | `` | ARN of the deployment role to assume. Set it when the configuration uses modules from the private `terraform-modules` repository. Leave it empty to run without AWS credentials |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | ARN of the OIDC entry role. The action uses it only when `deployment-role-arn` has a value |
| `aws-region` | No | `eu-west-2` | AWS region of the SSM parameter. The action uses it only when `deployment-role-arn` has a value |
| `modules-token-parameter` | No | `/shared/terraform-modules/exported/github/access-token` | SSM parameter that holds the GitHub access token. The action uses it only when `deployment-role-arn` has a value |

## What it does

1. Installs OpenTofu via `opentofu/setup-opentofu@v1`
2. **Modules access** (only when `deployment-role-arn` has a value): Assumes the OIDC entry role, then the deployment role. Reads the access token from `modules-token-parameter`. Git then uses the token for the `terraform-modules` repository (see `opentofu-modules-access`)
3. **Format**: Runs `tofu fmt -check -recursive`. The step fails if any file is not formatted
4. **Init (no backend)**: Runs `tofu init -backend=false` to download providers and modules
5. **Validate**: Runs `tofu validate` to check configuration correctness

## Requirements

- The action needs no AWS credentials when `deployment-role-arn` is empty. This works only when all modules are public or local.
- When `deployment-role-arn` has a value, the workflow needs the permission `id-token: write`. The role needs `ssm:GetParameter` on `modules-token-parameter`.
