# AWS Bedrock Plugin

Configure Claude Code to use AWS Bedrock.

## Commands

| Command | Description |
|---------|-------------|
| `/bedrock:manage` | Main menu - setup, configure, and manage Bedrock |
| `/bedrock:status` | Quick status check |
| `/bedrock:refresh` | Re-authenticate your SSO session |
| `/bedrock:thinking` | Configure reasoning depth (thinking mode) |

## Quick Start

1. Run `/bedrock:manage` to start the setup wizard
2. Select or configure your AWS SSO profile
3. Choose a region and model
4. Restart Claude Code when prompted

## Requirements

- AWS CLI installed (`brew install awscli`)
- AWS SSO configured with Bedrock access
- IAM permissions: `AmazonBedrockFullAccess` or equivalent
- **Optional**: `jq` for enhanced session status in hooks (`brew install jq`)

## Files

```
plugin/
├── commands/
│   ├── manage.md        # /bedrock:manage - main menu
│   ├── status.md        # /bedrock:status - quick status
│   ├── refresh.md       # /bedrock:refresh - auth refresh
│   └── thinking.md      # /bedrock:thinking - thinking mode
├── skills/
│   └── aws-bedrock/
│       └── SKILL.md     # AWS Bedrock reference
├── scripts/
│   └── src/             # TypeScript implementation
└── .claude-plugin/
    ├── plugin.json      # Plugin manifest
    └── hooks/           # Session and security hooks
```

## Configuration

Settings are stored in `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "your-profile",
    "AWS_REGION": "us-west-2",
    "ANTHROPIC_MODEL": "global.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "MAX_THINKING_TOKENS": "8192",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "8192",
    "DISABLE_PROMPT_CACHING": "0"
  },
  "awsAuthRefresh": "aws sso login --profile your-profile"
}
```

## Thinking Mode

Configure how deeply Claude reasons before responding:

| Preset | Reasoning | Output | Description |
|--------|-----------|--------|-------------|
| Focused | 4096 | 4096 | Quick deliberation for routine tasks |
| **Balanced** | 8192 | 8192 | Solid reasoning without overthinking (default) |
| Thorough | 16384 | 16384 | Extended deliberation for architecture decisions |

**Note:** This controls reasoning time, not context window (how much code Claude can see).

## Automatic Session Management

This plugin includes mechanisms to handle SSO session expiration:

1. **Proactive Check (SessionStart hook)**: When Claude Code starts, the plugin checks your SSO session status. If expired or expiring soon, you'll see a warning with instructions.

2. **Automatic Refresh (awsAuthRefresh)**: When configured, Claude Code automatically runs `aws sso login` when it detects expired credentials.

3. **Refresh Token Detection**: The plugin detects if you're using legacy SSO format (8-hour sessions) and suggests upgrading to 90-day sessions.

## Session Duration

| Configuration | Session Duration |
|--------------|------------------|
| Legacy SSO (without refresh tokens) | ~8 hours |
| SSO Session (with refresh tokens) | Up to 90 days |

The setup wizard guides you to configure `sso:account:access` scope for extended sessions.

## Troubleshooting

Run `/bedrock:status` to check for issues. Common problems:

- **Auth expired**: Run `/bedrock:refresh`
- **CLI not installed**: `brew install awscli`
- **Permission denied**: Contact your AWS administrator
- **Model not available**: Use inference profile with `global.` prefix
- **Sessions expire every 8 hours**: Reconfigure SSO with `sso:account:access` scope
- **Session warnings not showing**: Install `jq` (`brew install jq`)

## Manual Recovery

If Claude becomes unresponsive due to API errors:

1. Edit `~/.claude/settings.json`
2. Delete these keys from `"env"`:
   - `CLAUDE_CODE_USE_BEDROCK`
   - `AWS_PROFILE`
   - `AWS_REGION`
   - `ANTHROPIC_MODEL`
3. Delete `"awsAuthRefresh"` and `"model"` (if present)
4. Restart Claude Code
