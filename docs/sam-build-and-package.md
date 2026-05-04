# sam-build-and-package

Builds and packages a SAM application, uploading Lambda artifacts and the packaged template to S3 under `s3://aws-management-codepipeline/${environment}/sam/${sha}/`. The output S3 URI can be passed directly to `sam-deploy`.

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
  with:
    environment: "production"
    deployment-role-arn: "arn:aws:iam::123456789012:role/my-deploy-role"
    packaged-template-uri: ${{ steps.package.outputs.packaged-template-uri }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `environment` | Yes | - | Deployment environment (`development`, `staging`, `production`) |
| `deployment-role-arn` | Yes | - | ARN of the deployment role to assume for S3 upload |
| `template-file` | No | `template.yaml` | Path to the SAM template file |
| `aws-region` | No | `eu-west-2` | AWS region |
| `oidc-entry-role-arn` | No | `arn:aws:iam::020844256789:role/github-actions-oidc-entry-role` | OIDC entry role ARN |
| `summary-title` | No | `SAM Build & Package Summary` | Title for the GitHub Step Summary |
| `summary-icon` | No | `:package:` | Icon emoji for the summary |

## Outputs

| Output | Description |
|--------|-------------|
| `packaged-template-uri` | S3 URI of the packaged SAM template (pass to `sam-deploy`) |

## What it does

1. Authenticates via OIDC role chaining (entry role → deployment role)
2. Runs `sam build` to compile the application
3. Runs `sam package` to upload Lambda artifacts to `s3://aws-management-codepipeline/${environment}/sam/${sha}/`
4. Uploads the packaged template to the same S3 prefix
5. Outputs the S3 URI of the packaged template
6. Writes a build summary to the GitHub Step Summary

## Requirements

- The workflow must have `id-token: write` permission for OIDC authentication
- The deployment role must have `s3:PutObject` permissions on the `aws-management-codepipeline` bucket
- SAM CLI must be available on the runner (pre-installed on `ubuntu-latest`)
