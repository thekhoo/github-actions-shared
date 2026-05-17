# aws-cloudformation-delete-changeset

Deletes a CloudFormation change set. If deleting the change set leaves the stack in `REVIEW_IN_PROGRESS` (an empty stack created solely by the change set), the stack is also deleted. The action is idempotent — re-running against an already-deleted change set succeeds without error.

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

# Later, e.g. on PR close or after manual review rejection
- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-delete-changeset@main
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
| `changeset-arn` | Yes | - | ARN of the change set to delete (output from `aws-cloudformation-create-changeset`) |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume |
| `stack-name` | No | `${repo-name}-${environment}` | CloudFormation stack name |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `summary-title` | No | `CloudFormation Delete Change Set Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:wastebasket:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `stack-name` | Resolved CloudFormation stack name |
| `deleted` | `true` if the change set existed and was deleted, `false` if it was already gone |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. Resolves the stack name (input or `${repo-name}-${environment}`)
3. Checks whether the change set still exists; if gone, succeeds silently
4. Deletes the change set
5. Checks the stack status — if `REVIEW_IN_PROGRESS` (empty stack), deletes the stack and waits for completion
6. Writes a delete summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have permissions to describe/delete change sets and (for the cleanup step) delete stacks
