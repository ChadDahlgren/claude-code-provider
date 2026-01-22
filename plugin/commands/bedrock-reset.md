---
description: Remove AWS Bedrock configuration and return to default Anthropic API
---

# Bedrock Reset

Remove AWS Bedrock configuration and return to the default Anthropic API.

## Check Current Config

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

**If `configured: false`:**
```
Bedrock not configured

Nothing to reset.
```

## Confirm with User

Use `AskUserQuestion`:
- "Remove AWS Bedrock configuration? This will switch back to the default Anthropic API."
- Options: "Yes, reset" / "Cancel"

## Remove Configuration

If confirmed:

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js apply-config --remove
```

**Response:**
```json
{
  "success": true,
  "data": {
    "removed": true,
    "settingsPath": "~/.claude/settings.json"
  }
}
```

## Output

**Successful reset:**
```
✓ Bedrock configuration removed

Claude Code will now use the default Anthropic API.

⚠ RESTART REQUIRED
  Exit and restart Claude Code for changes to take effect.

To configure again: /bedrock
```

**User cancelled:**
```
Reset cancelled

Your configuration is unchanged.
Run /bedrock:status to see current settings.
```
