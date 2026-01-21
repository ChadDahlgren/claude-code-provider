# Contributing to Claude Code Bedrock Plugin

Thank you for your interest in contributing!

## Project Structure

```
claude-code-bedrock/
├── plugin/                     # The distributable plugin
│   ├── .claude-plugin/
│   │   ├── plugin.json         # Plugin manifest
│   │   └── hooks/              # Auto-approval hooks
│   ├── commands/
│   │   ├── bedrock.md          # Setup wizard (/bedrock)
│   │   ├── bedrock-status.md   # Status display (/bedrock:status)
│   │   ├── bedrock-diagnose.md # Diagnostics (/bedrock:diagnose)
│   │   ├── bedrock-refresh.md  # Re-authenticate (/bedrock:refresh)
│   │   └── bedrock-reset.md    # Remove config (/bedrock:reset)
│   ├── skills/
│   │   └── aws-bedrock/
│   │       └── SKILL.md        # AWS Bedrock reference material
│   └── README.md
├── dev/                        # Development tooling (not part of plugin)
│   ├── scripts/                # Reset scripts for testing
│   └── planning/               # Architecture docs
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Development Setup

### Prerequisites

- macOS (Homebrew for CLI installations)
- AWS CLI (`brew install awscli`)
- jq (`brew install jq`)
- Claude Code installed

### Local Testing

1. Clone the repository:
   ```bash
   git clone https://github.com/ChadDahlgren/claude-code-bedrock.git
   cd claude-code-bedrock
   ```

2. Test the plugin locally:
   ```bash
   claude --plugin-dir ./plugin
   ```

3. Reset configuration for fresh testing:
   ```bash
   ./dev/scripts/reset-aws-bedrock.sh
   ```

## How to Contribute

1. **Create a branch** — `git checkout -b feature/your-feature-name`
2. **Make your changes** — Follow existing patterns
3. **Test thoroughly** — Test all user flows
4. **Submit a PR** — With clear description of changes

## Command Guidelines

Commands are Markdown files that instruct Claude how to handle user requests.

**Key principles:**
- Only status indicators: ✓ ✗ (no decorative emojis)
- Clear error messages with actionable fixes
- Use `AskUserQuestion` for confirmations
- Always preserve existing settings when updating config

## Testing Checklist

### Setup Flow (`/bedrock`)
- [ ] First-time user (no AWS CLI)
- [ ] User with existing SSO profiles
- [ ] User with no SSO profiles
- [ ] Canceling at various steps

### Status (`/bedrock:status`)
- [ ] Not configured
- [ ] Configured with valid auth
- [ ] Configured with expired auth

### Diagnose (`/bedrock:diagnose`)
- [ ] All checks pass
- [ ] AWS CLI missing
- [ ] Profile missing
- [ ] SSO session expired

### Refresh (`/bedrock:refresh`)
- [ ] Successful refresh
- [ ] Not configured
- [ ] Authentication failure

### Reset (`/bedrock:reset`)
- [ ] Successful reset
- [ ] User cancels
- [ ] Not configured

## Questions?

Open an issue: https://github.com/ChadDahlgren/claude-code-bedrock/issues
