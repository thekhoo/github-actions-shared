#!/usr/bin/env bash
# Manage the credentials of the release GitHub App (thekhoo-actions-writer-agent).
#
#   release-app-credentials.sh store --app-id ID --private-key-file FILE
#       Save the App ID and the private key to SSM Parameter Store.
#   release-app-credentials.sh sync OWNER/REPO [OWNER/REPO ...]
#       Read both values from SSM and set them on each repository as the
#       secret RELEASE_APP_PRIVATE_KEY and the variable RELEASE_APP_ID.
#
# Options (both commands): --region REGION, --dry-run
# AWS credentials come from the environment (for example AWS_PROFILE).
set -euo pipefail

APP_ID_PARAMETER="/shared/github-actions-shared/exported/github/release-app/app-id"
PRIVATE_KEY_PARAMETER="/shared/github-actions-shared/exported/github/release-app/private-key"
REGION="eu-west-2"
DRY_RUN=false

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

confirm() {
  [[ "$DRY_RUN" == true ]] && return 0
  read -r -p "$1 [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || { echo "Aborted."; exit 1; }
}

store() {
  local app_id="" key_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --app-id) app_id="$2"; shift 2 ;;
      --private-key-file) key_file="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; usage ;;
    esac
  done
  [[ "$app_id" =~ ^[0-9]+$ ]] || { echo "--app-id must be the numeric App ID" >&2; exit 1; }
  [[ -f "$key_file" ]] || { echo "--private-key-file must be an existing file" >&2; exit 1; }
  grep -q "BEGIN RSA PRIVATE KEY\|BEGIN PRIVATE KEY" "$key_file" \
    || { echo "$key_file does not look like a PEM private key" >&2; exit 1; }

  echo "This overwrites these SSM parameters in $REGION:"
  echo "  $APP_ID_PARAMETER"
  echo "  $PRIVATE_KEY_PARAMETER"
  confirm "Continue?"

  run aws ssm put-parameter --region "$REGION" --name "$APP_ID_PARAMETER" \
    --type String --value "$app_id" --overwrite
  run aws ssm put-parameter --region "$REGION" --name "$PRIVATE_KEY_PARAMETER" \
    --type SecureString --value "file://$key_file" --overwrite
  [[ "$DRY_RUN" == true ]] || echo "Stored. Delete the local key file or move it to a password manager."
}

sync() {
  [[ $# -gt 0 ]] || { echo "Give at least one OWNER/REPO" >&2; usage; }
  local repos=("$@") app_id private_key

  app_id=$(aws ssm get-parameter --region "$REGION" --name "$APP_ID_PARAMETER" \
    --query Parameter.Value --output text)
  private_key=$(aws ssm get-parameter --region "$REGION" --name "$PRIVATE_KEY_PARAMETER" \
    --with-decryption --query Parameter.Value --output text)

  echo "This sets RELEASE_APP_PRIVATE_KEY and RELEASE_APP_ID on: ${repos[*]}"
  confirm "Continue?"

  local repo
  for repo in "${repos[@]}"; do
    if [[ "$DRY_RUN" == true ]]; then
      echo "[dry-run] gh secret set RELEASE_APP_PRIVATE_KEY --repo $repo"
      echo "[dry-run] gh variable set RELEASE_APP_ID --repo $repo"
    else
      printf '%s' "$private_key" | gh secret set RELEASE_APP_PRIVATE_KEY --repo "$repo"
      gh variable set RELEASE_APP_ID --repo "$repo" --body "$app_id"
    fi
  done
}

[[ $# -gt 0 ]] || usage
command="$1"; shift

# Pull the shared options out of the argument list.
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --region) REGION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage 0 ;;
    *) args+=("$1"); shift ;;
  esac
done

case "$command" in
  store) store "${args[@]}" ;;
  sync) sync "${args[@]}" ;;
  -h|--help) usage 0 ;;
  *) echo "Unknown command: $command" >&2; usage ;;
esac
