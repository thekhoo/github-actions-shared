# aws-cloudformation-validate

Validates CloudFormation templates using two stages: static linting with `cfn-lint`, then the AWS CloudFormation `validate-template` API.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-validate@main
  with:
    template-paths: "infrastructure/template.yml infrastructure/roles.yml"
    validation-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `template-paths` | Yes | - | Space-separated list of CloudFormation template paths |
| `validation-role-arn` | Yes | - | ARN of the deployment role to assume for AWS API validation |
| `python-version` | No | `3.13` | Python version |
| `aws-region` | No | `eu-west-2` | AWS region for validation |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |

## What it does

1. Checks out the repository and sets up Python with uv
2. **Static validation**: Runs `cfn-lint` on each template — fails fast if any template has lint errors
3. **AWS authentication**: Assumes the OIDC entry role, then chains to the deployment role
4. **API validation**: Runs `aws cloudformation validate-template` on each template

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The OIDC entry role must trust the GitHub Actions OIDC provider
- The deployment role must be assumable from the entry role (role chaining)
