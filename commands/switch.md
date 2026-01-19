---
description: Switch between configured cloud providers
---

# Provider Switch Command

Switch between configured cloud providers (AWS Bedrock, Google Vertex AI, Azure Foundry).

## Your Role

Allow users to quickly switch between already-configured providers without going through the full setup wizard again. This is a future feature for when users have multiple providers configured.

## Design Rules

- **Only show if multiple providers configured** — Don't show this if only one provider exists
- **Current provider marked clearly** — Use ● and [current] label
- **Remind about restart** — Switching requires restarting Claude Code
- **No decorative emojis** — Only ● ○ for active/inactive

## Output Format

### When Multiple Providers Configured

```
❯ /provider:switch

Switch provider

  [1] ● AWS Bedrock - cricut-dev (us-west-2) [current]
  [2] ○ Google Vertex AI - my-project (us-central1)

  [q] Cancel

Choice:
```

After user selects a different provider:

```
Switching to Google Vertex AI...

✓ Provider switched to Google Vertex AI
  Project: my-project
  Region: us-central1

Restart required
Exit Claude Code and run claude again to use the new provider.
```

### When Only One Provider Configured

```
❯ /provider:switch

Only one provider configured

You currently have only AWS Bedrock configured.

To configure another provider, run: /provider
```

### When No Providers Configured

```
❯ /provider:switch

No providers configured

To configure a provider, run: /provider
```

## Implementation Steps

### Step 1: Read All Configured Providers

Read `~/.claude/settings.json` and look for provider configurations:

**AWS Bedrock indicators:**
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "profile-name",
    "AWS_REGION": "region"
  }
}
```

**Google Vertex AI indicators (future):**
```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "GOOGLE_PROJECT_ID": "project-id",
    "GOOGLE_REGION": "region"
  }
}
```

**Azure Foundry indicators (future):**
```json
{
  "env": {
    "CLAUDE_CODE_USE_FOUNDRY": "1",
    "AZURE_RESOURCE_ID": "resource-id"
  }
}
```

### Step 2: Count Configured Providers

- If 0 providers: Show "No providers configured"
- If 1 provider: Show "Only one provider configured"
- If 2+ providers: Show switch menu

### Step 3: Display Switch Menu

List all configured providers with:
- Number for selection
- ● (filled circle) for active provider
- ○ (empty circle) for inactive providers
- Provider name and key details
- [current] label on active one

### Step 4: Switch Configuration

When user selects a provider:

1. **Update settings.json** to activate the chosen provider
   - Set the appropriate `USE_*` flag to "1"
   - Disable other provider flags
   - Keep all provider configs (don't delete)

Example: Switching from Bedrock to Vertex:
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "0",
    "AWS_PROFILE": "cricut-dev",
    "AWS_REGION": "us-west-2",
    "CLAUDE_CODE_USE_VERTEX": "1",
    "GOOGLE_PROJECT_ID": "my-project",
    "GOOGLE_REGION": "us-central1"
  },
  "awsAuthRefresh": "aws sso login --profile cricut-dev",
  "vertexAuthRefresh": "gcloud auth application-default login"
}
```

2. **Show success message** with new provider details

3. **Remind about restart**

### Step 5: Persist Configuration

Write the updated settings back to `~/.claude/settings.json`.

Use the apply-config script or do it carefully to preserve other settings.

## Helper Scripts

Could create a new script for this:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/switch-provider.sh <provider-name>
```

Or handle it directly in the command since it's just updating settings.json.

## Provider Details to Display

### AWS Bedrock
Format: `AWS Bedrock - <profile> (<region>)`
Example: `AWS Bedrock - cricut-dev (us-west-2)`

### Google Vertex AI (Future)
Format: `Google Vertex AI - <project> (<region>)`
Example: `Google Vertex AI - my-project (us-central1)`

### Azure Foundry (Future)
Format: `Azure Foundry - <resource-name>`
Example: `Azure Foundry - my-claude-resource`

## Error Handling

### Can't Read settings.json
```
✗ Error reading configuration

Could not read ~/.claude/settings.json
To reconfigure, run: /provider
```

### Invalid Provider Selection
```
Invalid choice

Please enter a number from the list or 'q' to cancel.
```

### Write Failure
```
✗ Could not save configuration

Failed to write to ~/.claude/settings.json
Check file permissions and try again.
```

## State Management

**Important:** When switching providers, we change which one is active but keep all configurations:

Before switch (Bedrock active):
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "cricut-dev",
    "AWS_REGION": "us-west-2"
  }
}
```

After switch to Vertex (both configs preserved):
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "0",
    "AWS_PROFILE": "cricut-dev",
    "AWS_REGION": "us-west-2",
    "CLAUDE_CODE_USE_VERTEX": "1",
    "GOOGLE_PROJECT_ID": "my-project",
    "GOOGLE_REGION": "us-central1"
  }
}
```

This allows quick switching back without re-configuration.

## Future Enhancement: Quick Toggle

Could add a quick toggle mode:
```
❯ /provider:switch --toggle
```

Automatically switches to the other configured provider (if only 2 exist).

## Phase Support

**Phase 1 (Current):** Not very useful since only Bedrock is supported
**Phase 4 (Multi-provider):** This becomes the primary way to switch between providers

For Phase 1, this command can show:
```
❯ /provider:switch

Provider switching is coming soon

This command will let you switch between AWS Bedrock,
Google Vertex AI, and Azure Foundry once they're all supported.

Currently configured:
  ● AWS Bedrock - cricut-dev (us-west-2)

Run /provider:status to see your current configuration.
```
