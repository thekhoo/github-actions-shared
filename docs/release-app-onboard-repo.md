# Release app: onboard a repository

Give a repository write access through `thekhoo-actions-writer-agent`.
The app must exist and its credentials must be in SSM. See [release-app-setup.md](release-app-setup.md).

## Steps

### 1. Install the app on the repository

1. Open the app page: GitHub → Settings → Developer settings → GitHub Apps → `thekhoo-actions-writer-agent`.
2. Click **Install App**, then the gear icon next to your account (or **Install** the first time).
3. Choose **Only select repositories**. Add the repository. Click **Save**.

### 2. Set the secret and the variable

Use AWS credentials that can read the two SSM parameters. Use a `gh` login that can administer the repository.

```bash
scripts/onboard-repo.sh
```

The script prompts for the repository name. A bare name such as `pyrail-uk` uses the owner `thekhoo`. You can also enter `owner/name`.
It builds the repository URL, checks that the repository exists, and then runs the `sync` command below.
At the end it prints the links for the two manual steps (3 and 1).

To set several repositories at once, or to skip the prompt, run the `sync` command directly:

```bash
scripts/release-app-credentials.sh sync thekhoo/<repository> thekhoo/<other-repository>
```

The script reads the App ID and the private key from SSM. It sets the variable `RELEASE_APP_ID` and the secret `RELEASE_APP_PRIVATE_KEY` on each repository you name. It asks for confirmation first. Add `--dry-run` to see the commands without running them.

### 3. Add the app to the ruleset bypass list

Skip this step if the workflow only opens pull requests.
Do this step if the workflow pushes to a protected branch.

1. Open the repository → Settings → Rules → Rulesets.
2. Open the ruleset that protects the branch.
3. Under "Bypass list", click **Add bypass**. Select `thekhoo-actions-writer-agent`.
4. Click **Save changes**.

### 4. Use the token in the workflow

```yaml
steps:
  - uses: actions/create-github-app-token@v2
    id: app-token
    with:
      app-id: ${{ vars.RELEASE_APP_ID }}
      private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}

  - uses: actions/checkout@v6
    with:
      token: ${{ steps.app-token.outputs.token }}
```

Use `steps.app-token.outputs.token` wherever the step needs the write access, for example in the `token` input of `actions/checkout` or `release-please-action`.
Check the latest major version of `actions/create-github-app-token` before you copy this snippet.

## Check that it works

Run the workflow. The step "Create GitHub App token" must pass. If it fails with "Not Found", the app is not installed on the repository (step 1). If a push is rejected with `GH013`, the app is not on the bypass list (step 3).

## Remove a repository

1. Remove the repository from the app installation (Settings → Applications → Installed GitHub Apps → Configure).
2. Delete the secret `RELEASE_APP_PRIVATE_KEY` and the variable `RELEASE_APP_ID` from the repository.
3. Remove the app from the ruleset bypass list.
