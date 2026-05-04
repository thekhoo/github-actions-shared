# aws-cloudformation-create-changeset

Validates a CloudFormation template, uploads it to S3 under `s3://aws-management-codepipeline/${environment}/cloudformation/${sha}/`, and creates a change set. The outputs can be passed directly to `aws-cloudformation-execute-changeset`.

Accepts either a local `template-file` (for templates with no local artifact references) or a `packaged-template-uri` from `aws-cloudformation-package` (for templates that reference local Lambda code, nested stacks, etc.). Exactly one must be provided.

## Usage

### Without local artifacts

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-create-changeset@main
  id: changeset
  with:
    environment: "production"
    template-file: "infrastructure/template.yml"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    parameters: "Universe=production ServiceName=my-service"

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-execute-changeset@main
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    changeset-arn: ${{ steps.changeset.outputs.changeset-arn }}
    stack-name: ${{ steps.changeset.outputs.stack-name }}
```

### With local artifacts (after aws-cloudformation-package)

```yaml
permissions:
  id-token: write

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-package@main
  id: package
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-create-changeset@main
  id: changeset
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    packaged-template-uri: ${{ steps.package.outputs.packaged-template-uri }}

- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-execute-changeset@main
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
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume |
| `template-file` | One of | - | Path to a local CloudFormation template. Mutually exclusive with `packaged-template-uri`. |
| `packaged-template-uri` | One of | - | S3 URI of a pre-packaged template (from `aws-cloudformation-package`). Mutually exclusive with `template-file`. |
| `stack-name` | No | `${repo-name}-${environment}` | CloudFormation stack name |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `parameters` | No | *(empty)* | Space-separated `KEY=VALUE` pairs for CloudFormation parameters |
| `capabilities` | No | `CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND` | CloudFormation capabilities |
| `summary-title` | No | `CloudFormation Change Set Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:memo:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `changeset-arn` | ARN of the created change set (pass to `aws-cloudformation-execute-changeset`) |
| `stack-name` | Resolved CloudFormation stack name |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. If `packaged-template-uri`: downloads the template from S3 for validation
3. Validates the template (via `aws-cloudformation-validate` — cfn-lint + AWS API validation)
4. If `template-file`: uploads the template to `s3://aws-management-codepipeline/${environment}/cloudformation/${sha}/template.yaml`
   If `packaged-template-uri`: uses the existing S3 location directly
5. Detects whether the stack exists to set the correct change set type (`CREATE` vs `UPDATE`)
6. Creates the change set and waits for it to be ready
   - Automatically tags with `Project`, `ManagedBy`, `GitCommit`, and `Environment`
7. Writes a summary to the GitHub Step Summary including all proposed resource changes

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have CloudFormation and S3 permissions on the `aws-management-codepipeline` bucket
