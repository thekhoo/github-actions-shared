# github-tag-release

A reusable workflow that runs [release-please](https://github.com/googleapis/release-please) with the release GitHub App token.

release-please keeps a release PR up to date from your conventional commits. When someone merges that PR, release-please tags the release and creates the GitHub Release. The workflow does not publish anything. Start the publish step from the `release: published` event.

## Usage

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  checks:
    uses: ./.github/workflows/checks.yml

  tag-release:
    needs: checks
    uses: thekhoo/github-actions-shared/.github/workflows/github-tag-release.yml@main
    with:
      app-id: ${{ vars.RELEASE_APP_ID }}
    secrets:
      private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
```

Start the publish workflow from the release:

```yaml
on:
  release:
    types: [published]
```

## Set the required keys

The workflow needs the App ID (`app-id`) and the App private key (`private-key`) of the release GitHub App, `thekhoo-actions-writer-agent`. Set both on each repository that calls the workflow.

1. Install the app on the repository: GitHub → Settings → Developer settings → GitHub Apps → `thekhoo-actions-writer-agent` → **Install App**. Choose **Only select repositories** and add the repository.
2. Set the variable `RELEASE_APP_ID` and the secret `RELEASE_APP_PRIVATE_KEY`. The values are in SSM in eu-west-2:

   | Value | SSM parameter | Set on the repository as |
   |-------|---------------|--------------------------|
   | App ID | `/shared/github-actions-shared/exported/github/release-app/app-id` | variable `RELEASE_APP_ID` |
   | Private key | `/shared/github-actions-shared/exported/github/release-app/private-key` | secret `RELEASE_APP_PRIVATE_KEY` |

   Run `scripts/onboard-repo.sh` from this repository. It prompts for the repository name, reads both values from SSM, and sets them. Use AWS credentials that can read the parameters and a `gh` login that can administer the repository.

   Or set them by hand under the repository Settings → Secrets and variables → Actions. The App ID is on the app page. Generate the private key there too, as a `.pem` file. GitHub shows it once.
3. If the workflow must push to a protected branch, add the app to the ruleset bypass list: repository Settings → Rules → Rulesets → Bypass list. The workflow only opens pull requests and tags releases, so it does not need the bypass in most cases. The release PR itself still needs the normal review and checks.

To create the app, store the credentials in SSM, or rotate the key, see [release-app-setup.md](release-app-setup.md). For the full onboarding steps, see [release-app-onboard-repo.md](release-app-onboard-repo.md).

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `app-id` | Yes | - | ID of the release GitHub App |
| `config-file` | No | `release-please-config.json` | Path to the release-please config file |
| `manifest-file` | No | `.release-please-manifest.json` | Path to the release-please manifest file |

## Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `private-key` | Yes | Private key of the release GitHub App |

## Outputs

| Output | Description |
|--------|-------------|
| `release-created` | `'true'` if this run created a release |
| `tag-name` | Tag of the release, for example `v1.3.0`. Empty when no release was created |

## What it does

1. Creates a token for the release GitHub App with `actions/create-github-app-token`.
2. Runs `googleapis/release-please-action` with that token.

The App token is needed for two reasons. Pull requests and releases that `GITHUB_TOKEN` creates do not start other workflows. The App can also be on the ruleset bypass list.

## Requirements

- The repository has a `release-please-config.json` and a `.release-please-manifest.json`. Set the manifest to the latest released version.
- The release GitHub App is installed on the repository, and the secret and the variable are set. See [Set the required keys](#set-the-required-keys).
- Use conventional commits (`feat:`, `fix:`, ...) on the default branch.
