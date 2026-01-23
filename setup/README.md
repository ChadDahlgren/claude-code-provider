# Claude Code + AWS Bedrock Setup

Interactive scripts to configure [Claude Code](https://docs.anthropic.com/en/docs/claude-code) to use AWS Bedrock instead of the Anthropic API.

## What These Scripts Do

- Install prerequisites (Homebrew, AWS CLI, Claude Code) if needed
- Configure AWS SSO authentication with your organization's SSO portal
- Set up 90-day refresh tokens (instead of 8-hour sessions)
- Verify Bedrock access and find a working region
- Write Claude Code settings to `~/.claude/settings.json`

## Quick Start (Run Directly from GitHub)

You can run the setup script directly without cloning the repository:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ChadDahlgren/claude-code-bedrock/main/setup/install.sh)
```

Or if you prefer the TUI version with a nicer interface:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ChadDahlgren/claude-code-bedrock/main/setup/install.sh) --tui
```

### What the One-Liner Does

1. Downloads the setup scripts to a temporary directory
2. Runs the interactive setup
3. Cleans up temporary files when done

## Local Installation

If you have the repository cloned:

```bash
# Basic version (works everywhere)
./setup/setup-claude-bedrock.sh

# TUI version (prettier, requires gum)
./setup/setup-claude-bedrock-tui.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `setup-claude-bedrock.sh` | Basic bash version - works on any system |
| `setup-claude-bedrock-tui.sh` | TUI version using [gum](https://github.com/charmbracelet/gum) for a polished experience |
| `lib/core.sh` | Shared functions used by both scripts |

## Options

```bash
# Run interactive setup
./setup-claude-bedrock.sh

# Disable Bedrock and revert to Anthropic API
./setup-claude-bedrock.sh --disable

# Show help
./setup-claude-bedrock.sh --help
```

## Prerequisites

The scripts will check for and offer to install:

- **Homebrew** (macOS only) - for installing other dependencies
- **AWS CLI v2** - for AWS authentication and Bedrock access
- **Claude Code** - the CLI tool itself

## What You'll Need

Before running the script, have ready:

- Your organization's **AWS SSO URL** (get this from your IT team)
- Access to a browser for SSO authentication

## Configuration

After setup, your settings are stored in `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_PROFILE": "your-profile",
    "AWS_REGION": "us-west-2",
    "ANTHROPIC_MODEL": "global.anthropic.claude-opus-4-5-20251101-v1:0",
    "CLAUDE_CODE_FAST_MODEL": "global.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "MAX_THINKING_TOKENS": "12000",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "10000"
  }
}
```

### Tuning Token Settings

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| `MAX_THINKING_TOKENS` | 12,000 | 4,096 - 16,384 | Controls reasoning depth. Lower = faster, higher = more thorough |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 10,000 | 4,096 - 16,384 | Maximum response length |

## Troubleshooting

### SSO Session Expired

Re-authenticate with:

```bash
aws sso login --profile your-profile
```

### Bedrock Access Denied

Contact your AWS administrator to ensure:
- Bedrock is enabled in your account
- Your role has `bedrock:*` permissions (or at least `bedrock:InvokeModel`)

### Check Current Configuration

```bash
cat ~/.claude/settings.json
```

### Disable Bedrock

To revert to using the Anthropic API directly:

```bash
./setup-claude-bedrock.sh --disable
```
