# Release app: setup

`thekhoo-actions-writer-agent` is a GitHub App on the `thekhoo` personal account.
Workflows use it to write to repositories that the ruleset protects. An example is the release bump commit on `main`.
It replaces the default `GITHUB_TOKEN` where that token is too weak. Pull requests that `GITHUB_TOKEN` opens do not start CI. Pull requests that the app opens do start CI.

## Current state

- The app exists and is private ("Only on this account").
- It is installed on `thekhoo/pyrail-uk`.
- `pyrail-uk` has the secret `RELEASE_APP_PRIVATE_KEY`. The app is on the bypass list of the `pyrail-uk` ruleset.
- The App ID and the private key are stored in SSM. See [Where the credentials live](#where-the-credentials-live).

To give another repository access, see [release-app-onboard-repo.md](release-app-onboard-repo.md).

## Where the credentials live

| Value | SSM parameter (eu-west-2) | Type | Repository secret or variable |
|-------|---------------------------|------|-------------------------------|
| App ID | `/shared/github-actions-shared/exported/github/release-app/app-id` | String | variable `RELEASE_APP_ID` |
| Private key (PEM) | `/shared/github-actions-shared/exported/github/release-app/private-key` | SecureString | secret `RELEASE_APP_PRIVATE_KEY` |

GitHub shows the private key once, when you generate it. SSM is the copy of record.
A standard-tier `SecureString` holds up to 4 KB. An RSA 2048 key is about 1.7 KB, so it fits.

## Create the app again

Do this only if the app is lost. Otherwise rotate the key (below).

1. Open GitHub → Settings → Developer settings → GitHub Apps → **New GitHub App**.
2. Set the name to `thekhoo-actions-writer-agent`. Set the Homepage URL to any URL, for example the repository URL.
3. Under Webhook, clear **Active**. The workflows do not need a webhook, and the form then does not ask for a URL.
4. Leave the Callback URL empty. Do not tick "Request user authorization during installation".
5. Set the repository permissions:
   - `Contents`: Read and write
   - `Pull requests`: Read and write
   - `Metadata`: Read-only (GitHub sets this)
6. Set "Where can this app be installed?" to **Only on this account**. Click **Create GitHub App**.
7. Note the **App ID**. It is a number. It is not the Client ID.
8. Under "Private keys", click **Generate a private key**. A `.pem` file downloads.
9. Store both values. See [Store the credentials](#store-the-credentials).
10. Install the app on each repository. See [release-app-onboard-repo.md](release-app-onboard-repo.md).

## Store the credentials

Use AWS credentials that can write SSM parameters in the target account.

```bash
scripts/release-app-credentials.sh store \
  --app-id <app id> \
  --private-key-file ~/Downloads/<key>.pem
```

The script asks for confirmation before it overwrites the two parameters. Add `--dry-run` to see the commands without running them.
After the script succeeds, delete the downloaded `.pem` file or move it to a password manager.

## Rotate the private key

1. On the app page, under "Private keys", click **Generate a private key**.
2. Run the `store` command above with the new file.
3. Run the `sync` command for every onboarded repository. See [release-app-onboard-repo.md](release-app-onboard-repo.md#set-the-secret-and-the-variable).
4. On the app page, delete the old key.
