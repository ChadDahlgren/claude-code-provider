---
description: Re-authenticate your cloud provider session
---

# Provider Refresh Command

Re-authenticate the current provider's session.

## Behavior

1. Read `~/.claude/settings.json` to determine active provider
2. Run the appropriate authentication command
3. Report result

## AWS Bedrock

If `CLAUDE_CODE_USE_BEDROCK` is `"1"`:

Use `AskUserQuestion`:
- "Re-authenticate AWS Bedrock? This will open your browser."
- Options: "Yes, open browser" / "Cancel"

If yes:
```bash
aws sso login --profile <AWS_PROFILE>
```

**Output:**
```
Re-authenticating AWS Bedrock
Profile: <profile>

Opening browser for SSO login...
```

After success:
```
✓ Authentication successful

Your SSO session is now active.
Run /provider:status to verify.
```

## Google Vertex AI

If `CLAUDE_CODE_USE_VERTEX` is `"1"`:

Use `AskUserQuestion`:
- "Re-authenticate Google Vertex AI? This will open your browser."
- Options: "Yes, open browser" / "Cancel"

If yes:
```bash
gcloud auth application-default login
```

**Output:**
```
Re-authenticating Google Vertex AI
Project: <project>

Opening browser for Google authentication...
```

After success:
```
✓ Authentication successful

Your credentials are now configured.
Run /provider:status to verify.
```

## No Provider Configured

```
No provider configured

Claude Code is using the default Anthropic API.
To configure a provider, run: /provider
```

## Error Handling

### AWS Bedrock Errors

**Profile not found:**
```
✗ Profile "<profile>" not found

Available profiles: <list from aws configure list-profiles>

Fix: Run /provider to reconfigure with a valid profile.
```

**SSO session expired (browser closed without completing):**
```
✗ SSO login cancelled or timed out

The browser authentication did not complete.
Try again: /provider:refresh
```

**Network timeout:**
```
✗ Network error during authentication

Check your internet connection, VPN, or corporate firewall.
Try again: /provider:refresh
```

**SSO portal unreachable:**
```
✗ Could not reach SSO portal

Verify your SSO start URL is correct.
Current profile: <profile>
Reconfigure: /provider
```

### Google Vertex AI Errors

**gcloud not found:**
```
✗ gcloud CLI not installed

Install with: brew install google-cloud-sdk
Then retry: /provider:refresh
```

**Browser auth cancelled:**
```
✗ Authentication cancelled

The browser authentication did not complete.
Try again: /provider:refresh
```

**Network timeout:**
```
✗ Network error during authentication

Check your internet connection, VPN, or corporate firewall.
Try again: /provider:refresh
```

**Invalid project:**
```
✗ Project "<project>" not found or inaccessible

List available projects: gcloud projects list
Reconfigure: /provider
```

### Generic Errors

**Unknown failure:**
```
✗ Authentication failed

Error: <error message from CLI>

Run /provider:diagnose for detailed troubleshooting.
```
