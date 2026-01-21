---
description: Configure Claude Code to use AWS Bedrock or Google Vertex AI
---

# Provider Setup Command

Guide the user through configuring Claude Code to use an enterprise cloud provider.

**Follow this document as a script** - execute each screen in order, use `AskUserQuestion` for choices, verify after each action.

## Screen 1: Provider Selection

```
❯ /provider

Claude Provider Setup

Select a provider:

  [1] AWS Bedrock
  [2] Google Vertex AI
  [3] Azure Foundry (coming soon)

  [s] View status
  [q] Cancel

Choice:
```

- `1` → AWS Bedrock flow
- `2` → Google Vertex AI flow
- `3` → Tell them it's coming soon
- `s` → Run `/provider:status`
- `q` → Exit

---

## AWS BEDROCK FLOW

### AWS Step 1: Check CLI

```bash
which aws && aws --version
```

**Not installed?** Use `AskUserQuestion`:
- "AWS CLI is required but not installed. How would you like to proceed?"
- Options: "Install with Homebrew" / "I'll install it manually"

If Homebrew: `brew install awscli`

### AWS Step 2: Check Profiles

```bash
aws configure list-profiles
```

For each profile, get its region:
```bash
aws configure get region --profile <profile-name>
```

**Profiles found?** Use `AskUserQuestion`:
- "Select an AWS profile to use with Bedrock"
- Options: List profiles with regions (e.g., "cricut-dev (us-west-2)")
- Add option: "Configure a new profile"

**No profiles?** Go to Fresh SSO Setup.

### AWS Step 2b: Fresh SSO Setup

Claude Code cannot run interactive terminal commands. Collect info with `AskUserQuestion`:
- "What is your AWS SSO start URL?" (e.g., `https://company.awsapps.com/start`)
- "What AWS region is your SSO configured in?" (us-west-2, us-east-1, eu-west-1)
- "What would you like to name this profile?" (e.g., `work-dev`)

Then display this cheat sheet:

```
I can't run interactive AWS commands directly. Please run this in your terminal:

┌─────────────────────────────────────────────────────────────────┐
│  aws configure sso                                              │
│                                                                 │
│  When prompted, enter:                                          │
│    SSO session name: {profile_name}                             │
│    SSO start URL: {sso_url}                                     │
│    SSO region: {sso_region}                                     │
│    SSO registration scopes: (press Enter for default)           │
│                                                                 │
│  Complete authentication in your browser, then:                 │
│    Default client Region: us-west-2 (or your preferred region)  │
│    CLI default output format: json                              │
│    CLI profile name: {profile_name}                             │
└─────────────────────────────────────────────────────────────────┘

Type 'done' when complete, or 'cancel' to abort.
```

Verify profile created:
```bash
aws configure list-profiles | grep -w "{profile_name}"
```

### AWS Step 3: Select Region

Use `AskUserQuestion`:
- "Select a Bedrock region"
- Options:
  - "us-west-2 (Oregon) - Recommended"
  - "us-east-1 (N. Virginia)"
  - "eu-west-1 (Ireland)"
  - "ap-northeast-1 (Tokyo)"

### AWS Step 4: Authenticate

```bash
aws sso login --profile <profile-name>
```

Tell user: "Opening browser for SSO login. Complete the authentication in your browser."

### AWS Step 5: Select Model

Query available Claude inference profiles:

```bash
aws bedrock list-inference-profiles --region <region> --query "inferenceProfileSummaries[?contains(modelArn, 'anthropic')].[inferenceProfileId,inferenceProfileName]" --output text
```

Use `AskUserQuestion` with the models returned. **Use the exact `inferenceProfileId`** - don't modify it.

### AWS Step 6: Confirm

```
Before we switch to Bedrock, here's how to undo if needed:

Settings file: ~/.claude/settings.json

To revert, set: "CLAUDE_CODE_USE_BEDROCK": "0"

Or delete these from "env": CLAUDE_CODE_USE_BEDROCK, AWS_PROFILE, AWS_REGION, ANTHROPIC_MODEL

⚠ You must restart Claude Code after setup.

Ready to proceed? [y/n]
```

### AWS Step 7: Apply Configuration

Read existing `~/.claude/settings.json`, merge (don't overwrite):

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "CLAUDE_CODE_USE_VERTEX": "0",
    "AWS_PROFILE": "<profile>",
    "AWS_REGION": "<region>",
    "ANTHROPIC_MODEL": "<model-id>"
  },
  "bedrockAuthRefresh": "aws sso login --profile <profile>"
}
```

**Critical**: `CLAUDE_CODE_USE_BEDROCK` must be exactly `"1"` (string, not number or boolean).

### AWS Step 8: Success

```
────────────────────────────────────────────
  ✓ AWS Bedrock configured
────────────────────────────────────────────

  Provider:     AWS Bedrock
  Profile:      <profile>
  Region:       <region>
  Model:        <model>
  Auto-refresh: on

⚠ RESTART REQUIRED
  Exit Claude Code and restart for Bedrock to take effect.

Quick tips:
  • /models — Switch models or see available Bedrock models
  • /provider:status — Check your current configuration

If something breaks, set "CLAUDE_CODE_USE_BEDROCK": "0" in ~/.claude/settings.json
```

Use `AskUserQuestion`:
- "Setup complete. Please restart Claude Code. What would you like to do?"
- Options: "Exit now (I'll restart)" / "Help me troubleshoot"

---

## GOOGLE VERTEX AI FLOW

### Vertex Step 1: Check CLI

```bash
which gcloud && gcloud --version | head -1
```

**Not installed?** Use `AskUserQuestion`:
- "gcloud CLI is required but not installed. How would you like to proceed?"
- Options: "Install with Homebrew" / "I'll install it manually"

If Homebrew: `brew install google-cloud-sdk`

### Vertex Step 2: Check Authentication

```bash
gcloud auth application-default print-access-token 2>/dev/null
```

**No token?** Run authentication:
```bash
gcloud auth application-default login
```

Tell user: "Opening browser for Google authentication."

### Vertex Step 3: Select Project

List available projects:
```bash
gcloud projects list --format="value(projectId)"
```

**Projects found?** Use `AskUserQuestion` with the list.

**No projects?** Show:
```
No Google Cloud projects found.

To create a project:
  1. Visit: https://console.cloud.google.com/projectcreate
  2. Create a new project
  3. Run /provider again
```

### Vertex Step 4: Select Region

Use `AskUserQuestion`:
- "Select a Vertex AI region"
- Options:
  - "us-central1 (Iowa) - Recommended"
  - "us-east5 (Columbus)"
  - "europe-west1 (Belgium)"
  - "europe-west4 (Netherlands)"
  - "asia-southeast1 (Singapore)"

### Vertex Step 5: Enable Vertex AI API

Check if API is enabled:
```bash
gcloud services list --enabled --filter="name:aiplatform.googleapis.com" --project=<project-id> 2>&1
```

**Not enabled?** Ask to enable:
```bash
gcloud services enable aiplatform.googleapis.com --project=<project-id>
```

### Vertex Step 6: Check Claude Access

Test if Claude models are accessible:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://global-aiplatform.googleapis.com/v1/projects/<project-id>/locations/global/publishers/anthropic/models/claude-sonnet-4-5@20250929:rawPredict" \
  -d '{"anthropic_version":"vertex-2023-10-16","messages":[{"role":"user","content":"hi"}],"max_tokens":1}'
```

**404 response?** Claude needs to be enabled in Model Garden:

```
Claude models not enabled.

Steps:
  1. Open: https://console.cloud.google.com/vertex-ai/model-garden?project=<project-id>
  2. Search for "Claude"
  3. Click on any Claude model
  4. Click "Enable" and accept terms

Press Enter when done.
```

### Vertex Step 7: Select Model

Vertex model format: `claude-sonnet-4-5@20250929` (uses `@` separator)

Use `AskUserQuestion`:
- "Select a Claude model"
- Options: Available models (verify with API probe if needed)

### Vertex Step 8: Confirm

```
Before we switch to Vertex AI, here's how to undo if needed:

Settings file: ~/.claude/settings.json

To revert, set: "CLAUDE_CODE_USE_VERTEX": "0"

Or delete these from "env": CLAUDE_CODE_USE_VERTEX, GOOGLE_PROJECT_ID, ANTHROPIC_VERTEX_REGION, ANTHROPIC_MODEL

⚠ You must restart Claude Code after setup.

Ready to proceed? [y/n]
```

### Vertex Step 9: Apply Configuration

Read existing `~/.claude/settings.json`, merge (don't overwrite):

```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "CLAUDE_CODE_USE_BEDROCK": "0",
    "GOOGLE_PROJECT_ID": "<project-id>",
    "ANTHROPIC_VERTEX_REGION": "<region>",
    "ANTHROPIC_MODEL": "<model-id>"
  },
  "vertexAuthRefresh": "gcloud auth application-default login"
}
```

### Vertex Step 10: Success

```
────────────────────────────────────────────
  ✓ Google Vertex AI configured
────────────────────────────────────────────

  Provider:     Google Vertex AI
  Project:      <project>
  Region:       <region>
  Model:        <model>
  Auto-refresh: on

⚠ RESTART REQUIRED
  Exit Claude Code and restart for Vertex AI to take effect.

Quick tips:
  • /models — Switch models or see available Vertex models
  • /provider:status — Check your current configuration

If something breaks, set "CLAUDE_CODE_USE_VERTEX": "0" in ~/.claude/settings.json
```

Use `AskUserQuestion`:
- "Setup complete. Please restart Claude Code. What would you like to do?"
- Options: "Exit now (I'll restart)" / "Help me troubleshoot"

---

## Error Handling

Handle errors inline with clear messages:

**CLI not installed**: Offer Homebrew or manual install
**Auth fails**: "Check network, try again with /provider or run the auth command manually"
**No profiles/projects**: Guide to create one
**API not enabled**: Offer to enable or link to console
**Permission denied**: "Ask your administrator for access"
**Can't write settings**: "Make sure ~/.claude directory exists: mkdir -p ~/.claude"
