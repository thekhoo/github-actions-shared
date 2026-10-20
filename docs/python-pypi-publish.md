# python-pypi-publish

To publish a new repository, follow [pypi-onboard-repo.md](pypi-onboard-repo.md).

A composite action that builds a ref and publishes it to a Python package index with trusted publishing (OIDC).

It does not calculate versions, tag, or create a GitHub Release. Run it after [`github-tag-release`](github-tag-release.md) (release-please) has created the release.

## Why an action and not a workflow

PyPI trusted publishing does not accept a reusable workflow in another repository ("Reusable workflows cannot currently be used as the workflow in a Trusted Publisher"). The publish fails with `invalid-publisher`. A composite action runs inside the caller's job, so the token names the caller's own workflow file, and that is the file you register on PyPI.

## Usage

Make a workflow in the repository that starts when a GitHub Release is published:

```yaml
name: PyPI Release

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
    runs-on: ubuntu-latest
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: thekhoo/github-actions-shared/.github/actions/python-pypi-publish@main
        with:
          ref: ${{ github.event.release.tag_name || inputs.tag }}
```

The job sets `environment` and the permission `id-token: write`.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `ref` | Yes | - | Git ref to build and publish, for example the release tag `v1.3.0` |
| `repository-url` | No | `https://upload.pypi.org/legacy/` | Upload URL of the package index |
| `build-command` | No | `uv build` | Command that builds the distributions into `packages-dir` |
| `packages-dir` | No | `dist` | Directory that holds the built distributions |
| `check-url` | No | *(empty)* | Index URL to check for files that already exist, so they are skipped instead of failing. For TestPyPI use `https://test.pypi.org/simple/` |

## Publish to TestPyPI

Use a separate environment and the TestPyPI upload URL:

```yaml
jobs:
  publish-test:
    runs-on: ubuntu-latest
    environment: testpypi
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: thekhoo/github-actions-shared/.github/actions/python-pypi-publish@main
        with:
          ref: ${{ github.event.release.tag_name }}
          repository-url: https://test.pypi.org/legacy/
          check-url: https://test.pypi.org/simple/
```

For another index, set `repository-url` to its upload URL and set up a trusted publisher on that index.

## Set up the trusted publisher

On the index (pypi.org or test.pypi.org), open the project → Publishing → add a trusted publisher with:

| Field | Value |
|-------|-------|
| Owner and repository | The repository that holds the workflow |
| Workflow name | The file name of the workflow that uses this action, for example `pypi-release.yml` |
| Environment | The `environment` of the publish job |

If publishing fails with `invalid-publisher`, compare these three fields with the claims in the log (`workflow_ref` and `environment`).

## What it does

1. Checks out `ref`.
2. Sets up `uv`.
3. Runs `build-command`.
4. Publishes `packages-dir` with `uv publish --trusted-publishing always`.

## Why `uv publish`

`pypa/gh-action-pypi-publish` cannot run inside another action. It builds the name of its container image from the outermost action's repository, so the nested call tries to pull `ghcr.io/thekhoo/github-actions-shared` and fails with `denied`. `uv publish` has no such limit. It does not create PEP 740 attestations, which the PyPA action creates by default.
