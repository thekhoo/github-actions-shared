# opentofu-validate

Validates OpenTofu configuration files: format check and config validation. Runs without a real backend (no AWS credentials required) — safe for CI and lint pipelines on every push or pull request.

## Usage

```yaml
- uses: thekhoo/github-actions-shared/.github/actions/opentofu-validate@main
  with:
    working-directory: 'infrastructure/tofu'
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `working-directory` | No | `.` | Directory containing OpenTofu configuration files |
| `opentofu-version` | No | `latest` | OpenTofu version to install (e.g. `1.8.0`, `latest`) |

## What it does

1. Installs OpenTofu via `opentofu/setup-opentofu@v1`
2. **Format check**: Runs `tofu fmt -check -recursive` — fails if any files are not formatted
3. **Init (no backend)**: Runs `tofu init -backend=false` to download providers without requiring AWS credentials
4. **Validate**: Runs `tofu validate` to check configuration correctness

## Requirements

- No AWS credentials required — backend is skipped during validation
