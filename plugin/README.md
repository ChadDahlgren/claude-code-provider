# AWS Bedrock Plugin

Configure Claude Code to use AWS Bedrock.

## Commands

| Command | Description |
|---------|-------------|
| `/bedrock` | Setup wizard - configure AWS Bedrock |
| `/bedrock:status` | Show current configuration and auth status |
| `/bedrock:refresh` | Re-authenticate your SSO session |
| `/bedrock:diagnose` | Run diagnostics and identify issues |
| `/bedrock:reset` | Remove configuration and return to Anthropic API |

## Quick Start

1. Run `/bedrock` to start the setup wizard
2. Select or configure your AWS SSO profile
3. Choose a region and model
4. Restart Claude Code when prompted

## Requirements

- AWS CLI installed (`brew install awscli`)
- AWS SSO configured with Bedrock access
- IAM permissions: `AmazonBedrockFullAccess` or equivalent

## Files

```
plugin/
├── commands/
│   ├── bedrock.md           # /bedrock - setup wizard
│   ├── bedrock-status.md    # /bedrock:status
│   ├── bedrock-refresh.md   # /bedrock:refresh
│   ├── bedrock-diagnose.md  # /bedrock:diagnose
│   └── bedrock-reset.md     # /bedrock:reset
├── skills/
│   └── aws-bedrock/
│       └── SKILL.md         # AWS Bedrock reference
└── .claude-plugin/
    └── plugin.json          # Plugin manifest
```

## Configuration

Settings are stored in `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "your-profile",
    "AWS_REGION": "us-west-2",
    "ANTHROPIC_MODEL": "global.anthropic.claude-opus-4-5-20251101-v1:0"
  },
  "bedrockAuthRefresh": "aws sso login --profile your-profile"
}
```

## Troubleshooting

Run `/bedrock:diagnose` to check for issues. Common problems:

- **Auth expired**: Run `/bedrock:refresh`
- **CLI not installed**: `brew install awscli`
- **Permission denied**: Contact your AWS administrator
- **Model not available**: Use inference profile with `global.` prefix
