# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains reusable GitHub Actions for Python projects, Docker deployments, and CloudFormation infrastructure. These actions are designed to be referenced in other repositories via `uses: thekhoo/github-actions-shared/.github/actions/<action-name>@main`.

## Instructions

- always use hyphens for action inputs (i.e. input-repository)
- prompt user with questions if requirements are ambiguous
- use short and accurate commit messages
- update documentation in docs/ after creating/modifying/deleting an action

## Architecture

Each action lives in `.github/actions/<action-name>/action.yml` and follows a composite action pattern. Full documentation for each action is in `docs/<action-name>.md` — read the relevant doc when modifying an action.

### Actions Index

**Python CI:**
- `python-setup-uv` — base Python + uv setup (used by linting and pytest)
- `python-linting` — ruff and pyrefly (uses python-setup-uv)
- `python-pytest` — pytest runner (uses python-setup-uv)

**Release:**
- `python-semantic-release` — version bump, commit, tag (no GitHub Release)
- `github-publish-release` — creates GitHub Release for a tag (run after PyPI publish)

**Reusable Workflows:**
- `python-ci` — linting + pytest matrix (workflow)
- `python-pypi-deploy` — semantic release → GitHub Release → PyPI publish (workflow)

**AWS CloudFormation:**
- `aws-cloudformation-validate` — cfn-lint + AWS API validation with OIDC role chaining
- `aws-cloudformation-deploy` — validates then deploys a stack (uses aws-cloudformation-validate)
- `aws-cloudformation-package` — packages a template, uploading local artifacts to S3 under `/${environment}/cloudformation/${sha}/`
- `aws-cloudformation-create-changeset` — validates, uploads template to S3, creates a change set (accepts local template-file or packaged-template-uri)
- `aws-cloudformation-execute-changeset` — executes a change set and waits for completion
- `aws-cloudformation-delete-changeset` — deletes a change set; also deletes the stack if left in `REVIEW_IN_PROGRESS`

**AWS SAM:**
- `sam-build-and-package` — builds and packages a SAM app, uploads artifacts to S3 under `/${environment}/sam/${sha}/`
- `sam-deploy` — deploys a packaged SAM template to CloudFormation (uses output from sam-build-and-package)

**Docker:**
- `docker-build-and-publish` — build and push image with buildx caching
- `docker-retag` — retag image at registry level without rebuild
- `aws-ecr-docker-build-and-publish` — build and push image to ECR (OIDC role chaining), tag with `commit-${sha}`
- `aws-ecr-docker-retag` — retag ECR image as `${environment}-sha256-${short-digest}` using crane (uses aws-ecr-docker-build-and-publish output)

**Orchestration:**
- `deploy-infrastructure-and-docker` — orchestrates deployment role, infrastructure, and docker retag (uses aws-cloudformation-deploy + docker-retag)

### Dependency Chain

```
python-linting ──┐
                 ├─→ python-setup-uv
python-pytest ───┘

python-semantic-release → (PyPI publish) → github-publish-release

python-pypi-deploy (workflow) → python-semantic-release
                               → github-publish-release (via publish-action)
                               → pypa/gh-action-pypi-publish

aws-cloudformation-deploy → aws-cloudformation-validate

aws-cloudformation-create-changeset → aws-cloudformation-validate
aws-cloudformation-execute-changeset → aws-cloudformation-create-changeset (via changeset-arn output)
aws-cloudformation-create-changeset → aws-cloudformation-package (optional, via packaged-template-uri)

sam-deploy → sam-build-and-package (via packaged-template-uri output)

aws-ecr-docker-retag → aws-ecr-docker-build-and-publish (consumes the commit-${sha} tag)

deploy-infrastructure-and-docker → aws-cloudformation-deploy
                                 → docker-retag
```

## Key Patterns

- **uv package manager**: `uv sync --frozen --dev` to install, `uv run <cmd>` to execute, `uv run --with <pkg> <cmd>` for transient tools
- **AWS OIDC role chaining**: entry role (`github-actions-oidc-entry-role` in account 020844256789) → deployment role
- **Action references**: `@main` (latest), `@<commit-sha>` (pinned), `@<tag>` (released). Changes to action.yml are immediately live for `@main`.
