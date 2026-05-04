# sam-deploy

Deploys a packaged SAM application to CloudFormation. Expects a packaged template S3 URI produced by `sam-build-and-package`. SAM handles template validation internally before deploying.

## Usage

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/sam-build-and-package@main
  id: package
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"

- uses: thekhoo/github-actions-shared/.github/actions/sam-deploy@main
  id: deploy
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    packaged-template-uri: ${{ steps.package.outputs.packaged-template-uri }}
    parameter-overrides: "Stage=production ServiceName=my-service"
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (`development`, `staging`, `production`) |
| `packaged-template-uri` | Yes | - | S3 URI of the packaged template (output from `sam-build-and-package`) |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume for CloudFormation deployment |
| `stack-name` | No | `${repo-name}-${environment}` | CloudFormation stack name |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `parameter-overrides` | No | *(empty)* | Space-separated `KEY=VALUE` pairs for SAM parameter overrides |
| `capabilities` | No | `CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` | CloudFormation capabilities |
| `summary-title` | No | `SAM Deploy Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:rocket:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `stack-outputs` | JSON string of the deployed stack's outputs |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. Downloads the packaged template from S3
3. Runs `sam deploy` — SAM validates the template internally before deploying
   - Automatically tags the stack with `Project`, `ManagedBy`, `GitCommit`, and `Environment`
   - Uses `--no-fail-on-empty-changeset` to handle no-op deployments gracefully
4. Fetches stack outputs and exports them as JSON
5. Writes a deployment summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have permissions to create/update the CloudFormation stack and its resources, and `s3:GetObject` on the `aws-management-codepipeline` bucket
- SAM CLI must be available on the runner (pre-installed on `ubuntu-latest`)
