# Contributing to Claude Provider Plugin

Thank you for your interest in contributing! This document will help you understand the project structure and how to make changes.

## Project Structure

```
claude-provider/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   ├── provider.md          # Main setup wizard (/provider)
│   ├── provider-status.md   # Status display (/provider:status)
│   ├── provider-diagnose.md # Diagnostics (/provider:diagnose)
│   ├── provider-refresh.md  # Re-authenticate (/provider:refresh)
│   └── provider-switch.md   # Switch providers (/provider:switch)
├── skills/
│   └── aws-bedrock-setup/
│       └── SKILL.md         # Deep knowledge about Bedrock setup
├── scripts/
│   ├── check-aws-cli.sh     # Check if AWS CLI is installed
│   ├── parse-aws-profiles.sh # Parse SSO profiles from config
│   ├── check-sso-session.sh # Check SSO session validity
│   └── apply-config.sh      # Apply config to settings.json
├── planning/
│   ├── specification.html   # Full specification document
│   └── prototype-cli-v2.html # Interactive UI prototype
├── README.md
└── CONTRIBUTING.md
```

## Development Setup

### Prerequisites

- macOS (for full testing)
- AWS CLI (for testing AWS integration)
- Claude Code installed
- Git

### Local Testing

1. Clone the repository:
   ```bash
   git clone https://github.com/ChadDahlgren/claude-code-provider.git
   cd claude-code-provider
   ```

2. Test the plugin locally:
   ```bash
   claude --plugin-dir ./claude-provider
   ```

3. Or install it globally:
   ```bash
   mkdir -p ~/.claude/plugins
   ln -s $(pwd) ~/.claude/plugins/claude-provider
   ```

## How to Contribute

### Adding New Features

1. **Check the specification** — See `planning/specification.html` for the complete design
2. **Create a branch** — `git checkout -b feature/your-feature-name`
3. **Make your changes** — Follow the existing patterns
4. **Test thoroughly** — Test all user flows
5. **Submit a PR** — With clear description of changes

### Improving Commands

Commands are written in Markdown and tell Claude how to handle user requests.

**Key principles:**
- Follow the exact UI specifications in `planning/specification.html`
- No decorative emojis (only ✓ ✗ ● ○)
- Friendly language (not technical jargon)
- Clear error messages with fixes
- Always preserve existing settings when updating config files

**Example command structure:**
```markdown
# Command Name

Brief description of what this command does.

## Your Role

What Claude should do when this command is invoked.

## Design Rules

- Rule 1
- Rule 2

## Output Format

Show example outputs for different scenarios.

## Implementation Steps

Step-by-step instructions for Claude.

## Error Handling

How to handle common errors.
```

### Improving Shell Scripts

Scripts handle low-level system operations.

**Guidelines:**
- Use `set -euo pipefail` for safety
- Provide clear exit codes and output format
- Document expected input/output
- Handle errors gracefully
- Test on macOS (primary platform)

**Testing a script:**
```bash
# Make it executable
chmod +x scripts/your-script.sh

# Test it
bash scripts/your-script.sh <args>
```

### Adding Skills

Skills provide deep knowledge to Claude about specific topics.

**Structure:**
- Comprehensive reference information
- Common issues and fixes
- Best practices
- Examples
- Resources

Skills are automatically loaded when relevant to the user's question.

## Testing Checklist

Before submitting a PR, test these scenarios:

### Setup Flow
- [ ] First-time user (no AWS CLI)
- [ ] User with existing SSO profiles
- [ ] User with no SSO profiles (fresh setup)
- [ ] Canceling at various steps
- [ ] Invalid inputs

### Status Command
- [ ] No provider configured
- [ ] Bedrock configured and auth valid
- [ ] Bedrock configured but auth expired

### Diagnose Command
- [ ] All checks pass
- [ ] AWS CLI missing
- [ ] Profile missing
- [ ] SSO session expired
- [ ] Wrong region

### Refresh Command
- [ ] Successful refresh
- [ ] No provider configured
- [ ] Authentication failure

### Scripts
- [ ] check-aws-cli.sh with and without AWS CLI
- [ ] parse-aws-profiles.sh with various config formats
- [ ] check-sso-session.sh with valid/expired/missing sessions
- [ ] apply-config.sh preserves existing settings

## Code Style

### Markdown (Commands & Skills)
- Use clear headers
- Break content into sections
- Include examples
- Use code blocks for commands
- Follow the specification's formatting

### Bash Scripts
- Use shellcheck for linting
- Comment complex logic
- Use meaningful variable names
- Prefer explicit over clever
- Handle edge cases

### JSON
- Use 2-space indentation
- Validate with `jq .` or similar
- Follow existing structure

## Common Issues

### Script Not Executable
```bash
chmod +x scripts/your-script.sh
```

### Settings.json Merge Fails
Always read existing settings first, then merge:
```python
settings = json.loads(existing_settings)
settings["env"]["NEW_VAR"] = "value"
```

### AWS CLI Tests Failing
Some tests require AWS CLI to be installed. Use mocks or skip if not available.

## Documentation

When adding features:
1. Update README.md if user-facing
2. Update SKILL.md if it affects Bedrock knowledge
3. Update this CONTRIBUTING.md if it affects development
4. Reference the specification in planning/

## Release Process

1. Update version in `.claude-plugin/plugin.json`
2. Update CHANGELOG (when we have one)
3. Tag the release: `git tag v0.1.0`
4. Push with tags: `git push --tags`

## Questions?

- Open an issue: https://github.com/ChadDahlgren/claude-code-provider/issues
- Check the spec: `planning/specification.html`
- See the prototype: `planning/prototype-cli-v2.html`

## Future Roadmap

See `planning/specification.html` Section 7 for planned features:

**Phase 2:** Google Vertex AI support
**Phase 3:** Azure Foundry support
**Phase 4:** Multi-provider switching

Contributions aligned with this roadmap are especially welcome!
