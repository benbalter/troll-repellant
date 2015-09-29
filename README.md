# Troll Repellent
A micro-service to automatically comment on and close issues opened by troublesome users.

## Usage
Troll repellent is tiny Sinatra app designed to run on services like Heroku. You'll need to do two things, configure the server and configure the webhook on GitHub.

### Configure the server
You need a Ruby server with the following environmental variables:
- `GITHUB_TOKEN` - A personal access token of a bot account
- `GITHUB_COMMENT_GIST_ID` - ID of a Gist with content of the desired comment
- `GITHUB_HOOK_SECRET` - Secret shared with webhook to authenticate payload
- `GITHUB_REPO` - Name of GitHub repo in the form of `owner/repo`
- `GITHUB_BLACKLIST` - Comma separated list of GitHub usernames to blacklist

If not using a service like Heroku, you can start the server with the `script/server` command.

### Configure the webhook
Navigate to the repository's settings, and create a new webhook with the following settings:
- URL: `[SERVER URL]/payload`
- Content Type: `application/json`
- Secret: Your shared secret (`GITHUB_HOOK_SECRET`)
- Select "let me select individual events" and check only the "issues" and "pull requests" events

That's it. The hook should automatically fire each time an issue or pull request is opened, and will comment on and close any issue opened by a blacklisted user.

## Running locally
1. `script/bootstrap`
2. `script/server`

You'll also probably want to [install ngrok](https://developer.github.com/webhooks/configuring/#using-ngrok) to test the hooks locally.
