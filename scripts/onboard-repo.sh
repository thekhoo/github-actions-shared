#!/usr/bin/env bash
# Onboard a repository to the release GitHub App (thekhoo-actions-writer-agent).
#
# Prompts for the repository name, builds its URL, checks that it exists, then
# reads the App ID and private key from SSM and sets them on the repository as
# the variable RELEASE_APP_ID and the secret RELEASE_APP_PRIVATE_KEY.
#
# Usage: onboard-repo.sh [--region REGION] [--dry-run]
# AWS credentials come from the environment (for example AWS_PROFILE).
# Run `gh auth login` first. The login must be able to administer the repository.
set -euo pipefail

OWNER="thekhoo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

read -r -p "Repository name (for example pyrail-uk, or owner/name): " input
[[ -n "$input" ]] || { echo "A repository name is required." >&2; exit 1; }

if [[ "$input" == */* ]]; then
  repo="$input"
else
  repo="$OWNER/$input"
fi
url="https://github.com/$repo"
echo "Repository URL: $url"

gh repo view "$repo" --json url --jq .url >/dev/null \
  || { echo "Cannot see $repo. Check the name and your gh login." >&2; exit 1; }

"$SCRIPT_DIR/release-app-credentials.sh" sync "$repo" "$@"

cat <<MESSAGE

Done. Two manual steps remain (see docs/release-app-onboard-repo.md):
  1. Install the app on the repository: https://github.com/settings/installations
  2. Add the app to the ruleset bypass list: $url/settings/rules
MESSAGE
