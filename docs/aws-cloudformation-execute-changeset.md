# aws-cloudformation-execute-changeset

Executes a CloudFormation change set and waits for the stack to reach a complete state. Expects the change set ARN produced by `aws-cloudformation-create-changeset`.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-create-changeset@main
  id: changeset
  with:
    environment: "production"
    template-file: "infrastructure/template.yml"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-execute-changeset@main
  id: deploy
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    changeset-arn: ${{ steps.changeset.outputs.changeset-arn }}
    stack-name: ${{ steps.changeset.outputs.stack-name }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (`development`, `staging`, `production`) |
| `changeset-arn` | Yes | - | ARN of the change set to execute (output from `aws-cloudformation-create-changeset`) |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume |
| `stack-name` | No | `${repo-name}-${environment}` | CloudFormation stack name |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `summary-title` | No | `CloudFormation Execute Change Set Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:rocket:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `stack-outputs` | JSON string of the deployed stack's outputs |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. Checks the current stack status to select the correct waiter (`CREATE` vs `UPDATE`)
3. Executes the change set
4. Waits for the stack to reach a complete state
5. Fetches stack outputs and exports them as JSON
6. Writes a deployment summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have permissions to execute change sets and manage the stack's resources
