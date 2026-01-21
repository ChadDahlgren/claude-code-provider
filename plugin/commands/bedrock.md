---
description: Configure Claude Code to use AWS Bedrock
---

# Bedrock Setup

Configure Claude Code to use AWS Bedrock for Claude API access.

## Step 1: Check Prerequisites

```bash
which aws && aws --version
```

**Not installed?** Use `AskUserQuestion`:
- "AWS CLI is required. Install it now?"
- Options: "Yes, install with Homebrew" / "No, I'll install manually"

If yes: `brew install awscli`

## Step 2: Select or Create Profile

```bash
aws configure list-profiles
```

**Profiles found?** Let user select one, or choose "Configure new profile"

**No profiles?** Collect SSO info via `AskUserQuestion`:
- SSO start URL (e.g., `https://company.awsapps.com/start`)
- SSO region (e.g., `us-west-2`)
- Profile name (e.g., `work-dev`)

Use `AskUserQuestion`:
- "Ready to configure AWS SSO? You'll need to run a command in your terminal."
- Options: "Yes, show me the command" / "Cancel setup"

If yes, tell user to run in their terminal:

```
Run: aws configure sso

Enter these values when prompted:
  SSO session name:    {profile_name}
  SSO start URL:       {sso_url}
  SSO region:          {sso_region}
  CLI profile name:    {profile_name}

Complete browser auth, then type 'done' here.
```

Use `AskUserQuestion`:
- "Did you complete the SSO setup?"
- Options: "Yes, it's done" / "I need help"

Verify: `aws configure list-profiles | grep -w "{profile_name}"`

## Step 3: Select Region

Use `AskUserQuestion` - "Select a Bedrock region":
- us-west-2 (Oregon) - Recommended, best model availability
- us-east-1 (N. Virginia)
- eu-west-1 (Ireland)
- ap-northeast-1 (Tokyo)

## Step 4: Authenticate

```bash
aws sso login --profile <profile>
```

Tell user: "Complete SSO login in your browser."

## Step 5: Select Model

Query available Claude models:

```bash
aws bedrock list-inference-profiles --profile <profile> --region <region> --output json | jq -r '.inferenceProfileSummaries[] | select(.inferenceProfileArn | contains("anthropic")) | [.inferenceProfileId, .inferenceProfileName] | @tsv'
```

Let user select. Use the exact `inferenceProfileId` returned.

**Why inference profiles?** Claude 4.5 models require inference profiles for on-demand access. The `global.` prefix is recommended for best availability.

## Step 6: Confirm and Apply

Use `AskUserQuestion`:
- "Ready to apply this configuration?"
- Show summary: Profile: {profile}, Region: {region}, Model: {model}
- Options: "Yes, apply" / "No, go back"

Merge into `~/.claude/settings.json` (preserve existing settings):

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "<profile>",
    "AWS_REGION": "<region>",
    "ANTHROPIC_MODEL": "<model-id>"
  },
  "bedrockAuthRefresh": "aws sso login --profile <profile>"
}
```

## Step 7: Done

```
✓ AWS Bedrock configured

  Profile:  <profile>
  Region:   <region>
  Model:    <model>

⚠ RESTART REQUIRED
  Exit and restart Claude Code for changes to take effect.

To undo: /bedrock:reset
```

## Error Handling

| Error | Fix |
|-------|-----|
| CLI not installed | Offer Homebrew install |
| Auth fails | Check network, retry, or run auth command manually |
| No profiles | Guide to create one via SSO |
| Permission denied | Contact administrator |
| Can't write settings | Run: `mkdir -p ~/.claude` |
