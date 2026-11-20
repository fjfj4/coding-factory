# Set up the factory GitHub App

The factory acts on GitHub as its own small GitHub App, not as you. You create the App once and install it on each product repo.

**Why an App and not a personal token?** An App token lasts one hour, works only on the repos you install it on, has only the permissions below, and can never change workflow files. Unlike the built-in `GITHUB_TOKEN`, labels and comments it adds start the next workflow, which is how one stage hands off to the next.

## 1. Create the App (about 3 minutes)

Open <https://github.com/settings/apps/new> and fill in:

| Field | Value |
|---|---|
| GitHub App name | Any free name, for example `jacob-factory`. Its bot will be called `<name>[bot]`. |
| Homepage URL | `https://github.com/fjfj4/coding-factory` |
| Webhook | Untick **Active**. The factory uses Actions, not webhooks. |
| Repository permissions | **Contents:** Read and write. **Issues:** Read and write. **Pull requests:** Read and write. **Checks:** Read and write. **Metadata:** Read-only (set automatically). Leave everything else at No access, **especially Workflows**. |
| Where can this App be installed? | Only on this account |

Click **Create GitHub App**. On the next page:

1. Note the **Client ID** (starts with `Iv`).
2. Under **Private keys**, click **Generate a private key**. A `.pem` file downloads. Treat it like a password.
3. In the left menu, click **Install App**, then install it on **Only select repositories** and pick the product repo (for the demo: `fjfj4/factory-demo`).

## 2. Get a Claude token

In a terminal on your laptop:

```powershell
claude setup-token
```

It prints a long-lived token for your Claude plan. Factory runs count against the same usage limits as your own Claude use.

## 3. Add the secrets and variables to the product repo

From the product repo folder (Git Bash or PowerShell), replacing the placeholders:

```powershell
gh secret set FACTORY_APP_PRIVATE_KEY < path\to\the-key.pem
gh secret set CLAUDE_CODE_OAUTH_TOKEN
gh variable set FACTORY_APP_CLIENT_ID --body "Iv..."
gh variable set FACTORY_BOT_LOGIN --body "jacob-factory[bot]"
```

`gh secret set CLAUDE_CODE_OAUTH_TOKEN` asks you to paste the token, so it never lands in your shell history. Then delete the `.pem` file from your Downloads folder; GitHub keeps no copy, but you can always generate a new key.

## 4. Start in dry-run mode

Leave `FACTORY_DRY_RUN` unset. The factory then only comments what it would do, without changing labels or creating issues. When its comments look right, switch it on:

```powershell
gh variable set FACTORY_DRY_RUN --body "false"
```

## 5. Try it

Write an issue with a clear goal and acceptance criteria, then add the `factory:ready` label. Within a minute or two the orchestrator comments with one of three answers: ready to build, questions for you, or a split into smaller issues. See the run under the repo's **Actions** tab, workflow `factory-orchestrator`.
