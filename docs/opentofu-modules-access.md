# opentofu-modules-access

Gives OpenTofu read access to the private `thekhoo/terraform-modules` repository.
The action reads a GitHub access token from an SSM parameter. It then makes Git use the token for that repository only.

`opentofu-deploy` and `opentofu-validate` use this action. You can also use it alone.

## Usage

Configure AWS credentials first. The role must be able to read the SSM parameter.

```yaml
permissions:
  id-token: write

steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123456789012:role/my-deployment-role
      aws-region: eu-west-2
  - uses: thekhoo/github-actions-shared/.github/actions/opentofu-modules-access@main
  - run: tofu init
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `parameter-name` | No | `/shared/terraform-modules/exported/github/access-token` | SSM SecureString parameter that holds the access token |
| `repository` | No | `thekhoo/terraform-modules` | GitHub repository (`owner/name`) that the token gives access to |
| `aws-region` | No | `eu-west-2` | AWS region of the SSM parameter |

## What it does

1. Reads the parameter with `aws ssm get-parameter --with-decryption`.
2. Masks the token in the workflow logs.
3. Writes the variables `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_n` and `GIT_CONFIG_VALUE_n` to `GITHUB_ENV`.
   These variables make Git rewrite `https://github.com/<repository>` to a URL that contains the token.
   Git does not rewrite URLs of other repositories.

The action keeps the token in environment variables only. It does not write the token to a Git config file on disk.
Each later step in the same job can read these variables. The workflow logs show the token as `***`.

## Requirements

- AWS credentials must be configured before this action runs.
- The role must have `ssm:GetParameter` on the parameter. The `aws-management` repository gives this permission to `github-actions-create-deployment-role`.
- Module sources must use HTTPS, for example `git::https://github.com/thekhoo/terraform-modules.git//storage/s3?ref=v1.0.0`.

To rotate the token, see the README of the `terraform-modules` repository.
