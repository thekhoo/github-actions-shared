# conventional-commits

A reusable workflow that fails when a commit on a pull request does not follow [Conventional Commits](https://www.conventionalcommits.org/).

release-please reads commit messages to choose the next version: `feat:` gives a minor release, `fix:` a patch release, and `feat!:` or a `BREAKING CHANGE:` footer a major release. Types such as `docs:`, `ci:` and `chore:` do not start a release.

## Usage

```yaml
name: CI

on:
  pull_request:
    branches: [main]

jobs:
  commit-messages:
    uses: thekhoo/github-actions-shared/.github/workflows/conventional-commits.yml@main
```

The workflow has no inputs.

## What it does

1. Checks out the full history (`fetch-depth: 0`).
2. Runs `webiny/action-conventional-commits` on the commits of the pull request.

## Require the check

To block merging on a bad commit message, add the check to the ruleset's required status checks. The check name is the caller job name followed by the job name of this workflow, for example `commit-messages / Validate Commit Messages`. Open a pull request first and copy the exact name from its checks list.

## Squash merges

The check validates the commits on the branch. A squash merge uses the pull request title (or the single commit message) as the commit on the default branch, and release-please reads that. Keep the title in the conventional format too.
