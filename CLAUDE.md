# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This repository contains reusable GitHub Actions for Python projects, Docker deployments, and CloudFormation infrastructure. These actions are designed to be referenced in other repositories via `uses: thekhoo/github-actions-shared/.github/actions/<action-name>@main`.

## Instructions

- always use hyphens for action inputs (i.e. input-repository)
- prompt user with questions if requirements are ambiguous

## Architecture

### Action Structure

Each action lives in `.github/actions/<action-name>/action.yml` and follows a composite action pattern. Actions are designed to be composable:

- **python-setup-uv**: Base action that sets up Python with `uv` package manager. Includes dependency caching and installs dependencies from `uv.lock`.
- **python-linting**: Composite action that uses `python-setup-uv`, then runs optional linting tools (ruff check/format, pyrefly typechecking).
- **python-pytest**: Composite action that uses `python-setup-uv`, then runs pytest on specified directories.
- **validate-cloudformation**: Performs two-stage validation: cfn-lint for static validation, then AWS CloudFormation validate-template API. Uses OIDC role chaining (entry role → deployment role).
- **docker-build-and-publish**: (Work in progress, currently empty)

### Dependency Chain

```
python-linting ──┐
                 ├─→ python-setup-uv
python-pytest ───┘

validate-cloudformation (standalone, includes own setup)
```

## Key Patterns

### UV Package Manager

All Python actions use `uv` instead of pip/poetry. Commands:
- `uv sync --frozen --dev`: Install dependencies from lockfile
- `uv run <command>`: Run commands in uv-managed environment
- `uv run --with <package> <command>`: Install and run tool transiently

### AWS Role Chaining

The CloudFormation validation action uses a two-step OIDC authentication:
1. Assume entry role: `github-actions-oidc-entry-role` (hardcoded in account 020844256789)
2. Chain to deployment role: Specified via `validation-role-arn` input

### Action References

When updating actions, remember that external repositories reference them via:
- `@main` for latest (typical usage)
- `@<commit-sha>` for pinned versions
- `@<tag>` for released versions

Changes to action.yml files are immediately live for `@main` references.
