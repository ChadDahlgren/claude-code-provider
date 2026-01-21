---
description: Remove provider configuration and return to default Anthropic API
---

# Provider Reset Command

Remove all provider configuration and return to the default Anthropic API.

## Behavior

1. Read `~/.claude/settings.json`
2. Confirm with user before removing
3. Remove provider-specific settings
4. Report result

## Confirmation

Use `AskUserQuestion`:
- "Remove all provider configuration? This will switch back to the default Anthropic API."
- Options: "Yes, reset to defaults" / "Cancel"

## Implementation

If confirmed, remove these keys from `~/.claude/settings.json`:

**From `env` section:**
- `CLAUDE_CODE_USE_BEDROCK`
- `CLAUDE_CODE_USE_VERTEX`
- `AWS_PROFILE`
- `AWS_REGION`
- `GOOGLE_PROJECT_ID`
- `ANTHROPIC_VERTEX_REGION`
- `ANTHROPIC_MODEL`

**From root:**
- `bedrockAuthRefresh`
- `vertexAuthRefresh`

**Important:** Preserve all other settings (MCP servers, hooks, etc.)

## Output

**Successful reset:**
```
✓ Provider configuration removed

Claude Code will now use the default Anthropic API.

To configure a provider again, run: /provider
```

**No provider configured:**
```
No provider configuration found

Claude Code is already using the default Anthropic API.
```

**User cancelled:**
```
Reset cancelled

Your current configuration is unchanged.
Run /provider:status to see current settings.
```
