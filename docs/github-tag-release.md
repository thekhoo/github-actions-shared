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
- The release GitHub App is installed on the repository. The secret and the variable are set. See [release-app-onboard-repo.md](release-app-onboard-repo.md).
- Use conventional commits (`feat:`, `fix:`, ...) on the default branch.
