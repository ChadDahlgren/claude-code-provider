---
description: Configure Claude Code to use AWS Bedrock
---

# Bedrock Setup

Configure Claude Code to use AWS Bedrock for Claude API access.

## Step 1: Check Prerequisites

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js check-prerequisites
```

**Response format:**
```json
{
  "success": true,
  "data": {
    "aws_cli": { "installed": true, "version": "..." },
    "node": { "installed": true, "version": "..." },
    "ready": true,
    "missing": []
  }
}
```

**If `ready: false`:**
- Show which tools are missing from the `missing` array
- Use `AskUserQuestion`: "Install missing tools with Homebrew?"
- If yes: `brew install awscli` (for aws-cli)

## Step 2: Get AWS Context

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js get-aws-context
```

**Response format:**
```json
{
  "success": true,
  "data": {
    "profiles": [...],
    "validProfiles": ["profile1", "profile2"],
    "bedrockProfiles": [],
    "recommended": "profile1",
    "currentConfig": null,
    "needsSsoSetup": false
  }
}
```

**If `needsSsoSetup: true` (no valid profiles):**
- Collect SSO info via `AskUserQuestion`:
  - SSO start URL (e.g., `https://company.awsapps.com/start`)
  - SSO region (e.g., `us-west-2`)
  - Profile name (e.g., `work-dev`)
- Tell user to run in their terminal:

```
Run: aws configure sso

Enter these values when prompted:
  SSO session name:        {profile_name}
  SSO start URL:           {sso_url}
  SSO region:              {sso_region}
  SSO registration scopes: sso:account:access   ← IMPORTANT for 90-day sessions!

Complete browser auth, then return here.
```

- After user confirms, re-run `get-aws-context` to verify

**If `recommended` exists:**
- Use `AskUserQuestion`: "Use profile '{recommended}'?"
- Options: "Yes, use {recommended}" / "Select different profile" / "Configure new profile"

**If `validProfiles` has multiple options and user wants to select:**
- Show list with `AskUserQuestion`

**If user selects "Configure new profile":**
- Collect SSO info via `AskUserQuestion` (all in one prompt if possible):
  - SSO start URL (e.g., `https://company.awsapps.com/start`)
  - SSO region (e.g., `us-west-2`)
  - Profile name (e.g., `work-dev`)
- Tell user to run in their terminal:

```
Run: aws configure sso

Enter these values when prompted:
  SSO session name:        {profile_name}
  SSO start URL:           {sso_url}
  SSO region:              {sso_region}
  SSO registration scopes: sso:account:access   ← IMPORTANT for 90-day sessions!

Complete browser auth, then return here.
```

- After user confirms, re-run `get-aws-context` to verify the new profile

## Step 3: Check Bedrock Access

Once profile is selected, check Bedrock access:

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js get-aws-context --check-bedrock --region=us-west-2
```

**If the selected profile shows `bedrockAccess: true`:**
- Show available `inferenceProfiles` for model selection
- Use `AskUserQuestion` to select model (recommend `global.anthropic.claude-opus-4-5-*`)

**If `bedrockAccess: false`:**
- May need SSO login first: `aws sso login --profile <profile>`
- Or check IAM permissions
- Try other regions if needed: us-east-1, eu-west-1, ap-northeast-1

## Step 4: Apply Configuration

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js apply-config --profile=<profile> --region=<region> --model=<model-id>
```

**Response format:**
```json
{
  "success": true,
  "data": {
    "applied": true,
    "config": { "profile": "...", "region": "...", "model": "..." },
    "settingsPath": "~/.claude/settings.json",
    "requiresRestart": true
  }
}
```

**If `success: false`:**
- Show the error message
- Common issues: expired credentials, missing Bedrock access, invalid model

## Step 5: Done

```
✓ AWS Bedrock configured

  Profile:  <profile>
  Region:   <region>
  Model:    <model>

⚠ RESTART REQUIRED
  Exit and restart Claude Code for changes to take effect.

To check status: /bedrock:status
To undo: /bedrock:reset

────────────────────────────────────────────
Manual Recovery (if Claude becomes unresponsive)

If Bedrock is misconfigured and Claude can't make API calls,
you won't be able to use /bedrock:reset. To manually fix:

1. Edit ~/.claude/settings.json
2. Delete these keys from "env":
   CLAUDE_CODE_USE_BEDROCK, AWS_PROFILE, AWS_REGION, ANTHROPIC_MODEL
3. Delete "awsAuthRefresh" and "model" (if present)
4. Restart Claude Code
```

## Error Handling

| Error | Fix |
|-------|-----|
| `ready: false` | Install missing tools (aws-cli) |
| `needsSsoSetup: true` | Run `aws configure sso` in terminal |
| `bedrockAccess: false` | Run `aws sso login` or check IAM permissions |
| `success: false` on apply | Check error message, verify profile/region/model |
| Sessions expire quickly | Reconfigure SSO with `sso:account:access` scope |
