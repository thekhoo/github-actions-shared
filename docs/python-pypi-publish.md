# python-pypi-publish

A reusable workflow that builds a ref and publishes it to a Python package index with trusted publishing (OIDC).

It does not calculate versions, tag, or create a GitHub Release. Run it after [`github-tag-release`](github-tag-release.md) (release-please) has created the release.

## Usage

Make a small workflow in the repository that starts when a GitHub Release is published:

```yaml
name: Publish

on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        description: Release tag to publish again (for example v1.1.0)
        required: true

jobs:
  publish:
    permissions:
      contents: read
      id-token: write
    uses: thekhoo/github-actions-shared/.github/workflows/python-pypi-publish.yml@main
    with:
      ref: ${{ github.event.release.tag_name || inputs.tag }}
```

The caller job must grant `id-token: write`. A reusable workflow cannot have more permissions than its caller.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `ref` | Yes | - | Git ref to build and publish, for example the release tag `v1.3.0` |
| `environment` | No | `production` | GitHub environment of the publish job. It must match the trusted publisher config on the index |
| `repository-url` | No | `https://upload.pypi.org/legacy/` | Upload URL of the package index |
| `build-command` | No | `uv build` | Command that builds the distributions into `packages-dir` |
| `packages-dir` | No | `dist` | Directory that holds the built distributions |
| `skip-existing` | No | `false` | Skip files that the index already has instead of failing |

## Publish to TestPyPI

Use a separate environment and the TestPyPI upload URL:

```yaml
jobs:
  publish-test:
    permissions:
      contents: read
      id-token: write
    uses: thekhoo/github-actions-shared/.github/workflows/python-pypi-publish.yml@main
    with:
      ref: ${{ github.event.release.tag_name }}
      repository-url: https://test.pypi.org/legacy/
      environment: testpypi
      skip-existing: true
```

For another index, set `repository-url` to its upload URL and set up a trusted publisher on that index.

## Set up the trusted publisher

On the index (pypi.org or test.pypi.org), open the project → Publishing → add a trusted publisher with:

| Field | Value |
|-------|-------|
| Owner and repository | The repository that holds the **caller** workflow |
| Workflow name | The file name of the caller workflow, for example `publish.yml` (not `python-pypi-publish.yml`) |
| Environment | The value of the `environment` input |

PyPI checks the caller's workflow file. If publishing fails with a trusted publisher error, check these three fields first.

## What it does

1. Checks out `ref`.
2. Sets up `uv`.
3. Runs `build-command`.
4. Publishes `packages-dir` with `pypa/gh-action-pypi-publish`.
