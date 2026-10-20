# Publish a Python repository to PyPI

Use this procedure to make a Python repository publish to PyPI with the shared release workflows.

When you finish, this sequence runs for every release:

1. A merge to `main` updates a release pull request (PR). The release PR holds the new version and the changelog.
2. The release PR merges. release-please creates the tag and the GitHub Release.
3. The GitHub Release starts the PyPI publish.

The `pyrail-uk` repository uses this setup. Copy its files in step 5: <https://github.com/thekhoo/pyrail-uk/tree/main/.github/workflows>.

## What you need

- A Python repository on GitHub, in the `thekhoo` account.
- The release GitHub App `thekhoo-actions-writer-agent`. See [release-app-setup.md](release-app-setup.md).
- AWS credentials that can read the SSM parameters of the release app.
- A PyPI account that can create or manage the project.
- The `gh` command-line tool, signed in with a login that can administer the repository.
- Commit messages that follow [Conventional Commits](https://www.conventionalcommits.org/). release-please reads them to choose the version.

## Procedure

### 1. Check `pyproject.toml`

1. Make sure `[project]` has a `name` and a `version`. release-please changes the `version` line.
2. Make sure `uv build` creates a wheel and a source distribution in `dist/`.
3. Make sure the `name` is the name you want on PyPI.

### 2. Give the repository access to the release app

1. Install the release app on the repository.
2. Run `scripts/onboard-repo.sh` from this repository.
3. Enter the repository name when the script asks.

The script sets the secret `RELEASE_APP_PRIVATE_KEY` and the variable `RELEASE_APP_ID`. For the full steps, see [release-app-onboard-repo.md](release-app-onboard-repo.md).

### 3. Allow auto-merge

Do this step only if the release PR must merge without a manual step.

1. Open the repository on GitHub.
2. Go to Settings, then General, then Pull Requests.
3. Select **Allow auto-merge**.

### 4. Add the release-please files

Create `release-please-config.json` in the root of the repository. Replace `<package-name>` with the PyPI project name.

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "python",
      "package-name": "<package-name>",
      "include-component-in-tag": false
    }
  }
}
```

Create `.release-please-manifest.json` in the root of the repository. Set the value to the latest version on PyPI. Use `0.0.0` if the package is new.

```json
{
  ".": "0.0.0"
}
```

### 5. Add the workflows

Copy these four files from `pyrail-uk` to `.github/workflows/` in the new repository:

| File | Starts on | Purpose |
|------|-----------|---------|
| `checks.yml` | Called by other workflows | Defines the lint and test checks one time |
| `ci.yml` | Pull request | Checks commit messages and calls `checks.yml` |
| `release.yml` | Push to `main` | Calls `checks.yml`, then `github-tag-release` |
| `pypi-release.yml` | GitHub Release published | Publishes the tag to PyPI |

Change these values after you copy the files:

- In `checks.yml`, set `lint-directories` and `test-directories` to the directories of the new repository.
- In `checks.yml`, set `pytest-python-versions` to the Python versions that the package supports.
- In `release.yml`, remove `auto-merge: true` if you did not do step 3.
- Do not change the file name `pypi-release.yml` unless you also change the trusted publisher in step 7.

Each workflow uses a shared workflow or action from this repository. See [github-tag-release.md](github-tag-release.md), [python-pypi-publish.md](python-pypi-publish.md) and [conventional-commits.md](conventional-commits.md).

### 6. Create the GitHub environment

1. Open the repository on GitHub.
2. Go to Settings, then Environments.
3. Create an environment named `production`.

The `publish` job in `pypi-release.yml` uses this environment. Add a required reviewer to the environment if you want a manual check before each publish.

### 7. Add the trusted publisher on PyPI

Trusted publishing lets the workflow publish without a stored password.

1. Sign in to <https://pypi.org>.
2. If the project does not exist, open <https://pypi.org/manage/account/publishing/> and add a pending publisher.
3. If the project exists, open the project, then Publishing, and add a publisher.
4. Enter these values:

| Field | Value |
|-------|-------|
| PyPI project name | The `name` in `pyproject.toml` |
| Owner | `thekhoo` |
| Repository name | The name of the repository |
| Workflow name | `pypi-release.yml` |
| Environment name | `production` |

The workflow name must be the file that contains the publish job. Do not enter `python-pypi-publish.yml`. PyPI rejects a reusable workflow from another repository.

To publish to TestPyPI, see [python-pypi-publish.md](python-pypi-publish.md#publish-to-testpypi).

### 8. Update the repository ruleset

1. Open the repository ruleset for `main`.
2. Add these required status checks. Copy the exact names from a pull request that ran the checks:
   - `PR / Checks / Lint`
   - `PR / Checks / Test (Python <version>)` for each Python version
   - `Commit Messages / Validate Commit Messages`
3. Add the release app to the bypass list if the repository requires a review.

Auto-merge does not skip the review rule. A repository with one author needs a relaxed review rule or the app bypass.

### 9. Make the first release

1. Merge a pull request with a `feat:` or `fix:` commit into `main`.
2. Open the Actions tab. Wait for the `Release` workflow to finish.
3. Open the pull request list. Find the PR with the title `chore(main): release <version>`.
4. Merge this PR, or wait for auto-merge to merge it.
5. Wait for the `Release` workflow to run again. This run creates the tag and the GitHub Release.
6. Wait for the `PyPI Release` workflow to finish.
7. Open the project page on PyPI. Make sure the new version is on the page.

## How the version is chosen

release-please reads the commit messages on `main` since the last release.

| Commit | Version change |
|--------|----------------|
| `fix:` | Patch (1.0.4 to 1.0.5) |
| `feat:` | Minor (1.0.4 to 1.1.0) |
| `feat!:` or a `BREAKING CHANGE:` footer | Major (1.0.4 to 2.0.0) |
| `docs:`, `ci:`, `chore:`, `test:` | No release |

To force a version, add `Release-As: <version>` as a footer in a commit message.

## Publish a tag again

1. Open the Actions tab.
2. Select the `PyPI Release` workflow.
3. Select **Run workflow**.
4. Enter the tag, for example `v1.1.0`.

## If something fails

| Symptom | Cause | Action |
|---------|-------|--------|
| `Release` fails at start with `startup_failure` | A job asks for more permissions than the caller grants | Compare the `permissions` of the caller job with the called workflow |
| `Create GitHub App token` fails with `Not Found` | The release app is not installed on the repository | Do step 2 |
| `Create GitHub App token` fails with an input error | The variable `RELEASE_APP_ID` or the secret `RELEASE_APP_PRIVATE_KEY` is missing | Run `scripts/onboard-repo.sh` |
| The release PR does not merge | The ruleset requires a review or a check that did not pass | Do step 8 |
| No release PR appears | No commit since the last release has the type `feat` or `fix` | Add a `feat:` or `fix:` commit |
| `PyPI Release` fails with `invalid-publisher` | The trusted publisher does not match the workflow | Compare the fields in step 7 with the `workflow_ref` and `environment` claims in the log |
| `PyPI Release` does not start after a release | The release is a draft, or the app token was not used to create it | Make sure `release.yml` calls `github-tag-release` with the app secret |
| `PyPI Release` fails with a `403` from PyPI | PyPI does not let this account publish the project name | Check the project name on PyPI and the `name` in `pyproject.toml` |
