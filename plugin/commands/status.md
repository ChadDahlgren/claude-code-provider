---
description: Show current provider configuration and authentication status
---

# Provider Status Command

Show the current Claude Code provider configuration.

## Behavior

1. Read `~/.claude/settings.json`
2. Check authentication status
3. Display configuration summary

## No Provider Configured

```
Claude Provider Status
────────────────────────────────────────────

No provider configured

Claude Code is using the default Anthropic API.

To configure a provider, run: /provider

Supported providers:
  • AWS Bedrock
  • Google Vertex AI
  • Azure Foundry (coming soon)
```

## AWS Bedrock Active

Check auth status:
```bash
aws sts get-caller-identity --profile <AWS_PROFILE> 2>&1
```

**Auth valid:**
```
Claude Provider Status
────────────────────────────────────────────

Active Provider
  Provider:     AWS Bedrock
  Profile:      <profile>
  Region:       <region>
  Auth:         ✓ valid
  Auto-refresh: on

Commands: /provider:diagnose • /provider:switch • /provider:refresh
```

**Auth expired:**
```
Claude Provider Status
────────────────────────────────────────────

Active Provider
  Provider:     AWS Bedrock
  Profile:      <profile>
  Region:       <region>
  Auth:         ✗ expired
  Auto-refresh: on

⚠ Your SSO session has expired

To re-authenticate:
  /provider:refresh

Or run manually:
  aws sso login --profile <profile>
```

## Google Vertex AI Active

Check auth status:
```bash
gcloud auth application-default print-access-token 2>&1
```

**Auth valid:**
```
Claude Provider Status
────────────────────────────────────────────

Active Provider
  Provider:     Google Vertex AI
  Project:      <project>
  Region:       <region>
  Auth:         ✓ valid
  Auto-refresh: on

Commands: /provider:diagnose • /provider:switch • /provider:refresh
```

**Auth expired:**
```
Claude Provider Status
────────────────────────────────────────────

Active Provider
  Provider:     Google Vertex AI
  Project:      <project>
  Region:       <region>
  Auth:         ✗ expired
  Auto-refresh: on

⚠ Your credentials have expired

To re-authenticate:
  /provider:refresh

Or run manually:
  gcloud auth application-default login
```

## Configuration Reference

**AWS Bedrock in settings.json:**
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "profile-name",
    "AWS_REGION": "us-west-2"
  },
  "bedrockAuthRefresh": "aws sso login --profile profile-name"
}
```

**Google Vertex AI in settings.json:**
```json
{
  "env": {
    "CLAUDE_CODE_USE_VERTEX": "1",
    "GOOGLE_PROJECT_ID": "project-id",
    "ANTHROPIC_VERTEX_REGION": "us-central1"
  },
  "vertexAuthRefresh": "gcloud auth application-default login"
}
```
