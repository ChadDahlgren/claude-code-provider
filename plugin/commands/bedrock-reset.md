---
description: Remove AWS Bedrock configuration and return to default Anthropic API
---

# Bedrock Reset

Remove AWS Bedrock configuration and return to the default Anthropic API.

## Behavior

1. Read `~/.claude/settings.json`
2. Confirm with user before removing
3. Remove Bedrock-specific settings
4. Report result

## Confirmation

Use `AskUserQuestion`:
- "Remove AWS Bedrock configuration? This will switch back to the default Anthropic API."
- Options: "Yes, reset" / "Cancel"

## Implementation

If confirmed, remove these keys from `~/.claude/settings.json`:

**From `env` section:**
- `CLAUDE_CODE_USE_BEDROCK`
- `AWS_PROFILE`
- `AWS_REGION`
- `ANTHROPIC_MODEL`

**From root:**
- `bedrockAuthRefresh`

**Important:** Preserve all other settings (MCP servers, hooks, etc.)

## Output

**Successful reset:**
```
✓ Bedrock configuration removed

Claude Code will now use the default Anthropic API.

To configure again: /bedrock
```

**Not configured:**
```
Bedrock not configured

Nothing to reset.
```

**User cancelled:**
```
Reset cancelled

Your configuration is unchanged.
Run /bedrock:status to see current settings.
```
