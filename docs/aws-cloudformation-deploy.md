# aws-cloudformation-deploy

Validates and deploys a CloudFormation stack with optional parameters. Runs `aws-cloudformation-validate` internally before deploying.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-deploy@main
  id: deploy
  with:
    stack-name: "production-my-service"
    template-file: "infrastructure/template.yml"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    parameters: "Universe=production ServiceName=my-service"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `stack-name` | Yes | - | CloudFormation stack name |
| `template-file` | Yes | - | Path to CloudFormation template |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `parameters` | No | *(empty)* | Space-separated `KEY=VALUE` pairs for CloudFormation parameters |
| `capabilities` | No | `CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` | CloudFormation capabilities |
| `summary-title` | No | `Deployment Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:rocket:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `stack-outputs` | JSON string of the deployed stack's outputs |

## What it does

1. Authenticates via OIDC role chaining (entry role -> deployment role)
2. Validates the template (via `aws-cloudformation-validate`)
3. Deploys the stack with `aws cloudformation deploy`
   - Automatically tags the stack with `Project`, `ManagedBy`, and `GitCommit`
   - Uses `--no-fail-on-empty-changeset` to handle no-op deployments gracefully
4. Fetches stack outputs and exports them as JSON
5. Writes a deployment summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have permissions to create/update the CloudFormation stack and its resources
