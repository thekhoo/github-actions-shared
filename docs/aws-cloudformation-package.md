# aws-cloudformation-package

Packages a CloudFormation template by uploading local artifacts (Lambda code, nested stacks, etc.) to S3 and rewriting the template with S3 URIs. Use this before `aws-cloudformation-create-changeset` when your template references local files.

If your template has no local artifact references, skip this action and pass `template-file` directly to `aws-cloudformation-create-changeset`.

## Usage

```yaml
permissions:
  id-token: write

# With local artifacts (e.g. Lambda zip files, nested stacks)
- uses: thekhoo/github-actions-shared/.github/actions/aws-cloudformation-package@main
  id: package
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    template-file: "infrastructure/template.yml"

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
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume for S3 upload |
| `template-file` | No | `template.yaml` | Path to the CloudFormation template file |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `summary-title` | No | `CloudFormation Package Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:package:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `packaged-template-uri` | S3 URI of the packaged template (pass to `aws-cloudformation-create-changeset`) |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. Runs `aws cloudformation package` to upload local artifacts to `s3://aws-management-codepipeline/${environment}/cloudformation/${sha}/` and rewrite local paths as S3 URIs
3. Uploads the packaged template to the same S3 prefix
4. Outputs the S3 URI of the packaged template
5. Writes a summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have `s3:PutObject` permissions on the `aws-management-codepipeline` bucket
