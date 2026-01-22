---
description: Show current AWS Bedrock configuration and authentication status
---

# Bedrock Status

Show the current AWS Bedrock configuration and authentication status.

## Behavior

1. Read `~/.claude/settings.json`
2. Check if Bedrock is configured
3. Check authentication status
4. Display configuration summary

## Not Configured

```
Bedrock Status
────────────────────────────────────────────

Not configured

AWS Bedrock is not set up.

To configure: /bedrock
```

## Configured - Auth Valid

Check auth status:
```bash
aws sts get-caller-identity --profile <AWS_PROFILE> 2>&1
```

**Auth valid:**
```
Bedrock Status
────────────────────────────────────────────

  Profile:  <profile>
  Region:   <region>
  Model:    <model>
  Auth:     ✓ valid

Commands: /bedrock:diagnose • /bedrock:refresh • /bedrock:reset
```

## Configured - Auth Expired

**Auth expired:**
```
Bedrock Status
────────────────────────────────────────────

  Profile:  <profile>
  Region:   <region>
  Model:    <model>
  Auth:     ✗ expired

⚠ Your SSO session has expired

To fix: /bedrock:refresh

Or manually: aws sso login --profile <profile>
```

## Configuration Reference

**Settings in ~/.claude/settings.json:**
```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "profile-name",
    "AWS_REGION": "us-west-2",
    "ANTHROPIC_MODEL": "global.anthropic.claude-opus-4-5-20251101-v1:0"
  },
  "awsAuthRefresh": "aws sso login --profile profile-name"
}
```
