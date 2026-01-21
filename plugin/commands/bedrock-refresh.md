---
description: Re-authenticate your AWS Bedrock SSO session
---

# Bedrock Refresh

Re-authenticate the AWS SSO session.

## Behavior

1. Read `~/.claude/settings.json`
2. Confirm with user
3. Run SSO login
4. Report result

## Not Configured

```
Bedrock not configured

To set up AWS Bedrock: /bedrock
```

## Refresh Flow

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
Run /bedrock:status to verify.
```

## Error Handling

**Profile not found:**
```
✗ Profile "<profile>" not found

Available profiles: <list from aws configure list-profiles>

To fix: /bedrock to reconfigure
```

**SSO login cancelled:**
```
✗ SSO login cancelled or timed out

The browser authentication did not complete.

To fix: /bedrock:refresh
```

**Network timeout:**
```
✗ Network error during authentication

Check your internet connection, VPN, or corporate firewall.

To fix: /bedrock:refresh
```

**SSO portal unreachable:**
```
✗ Could not reach SSO portal

Verify your SSO start URL is correct.
Current profile: <profile>

To fix: /bedrock to reconfigure
```

**Unknown failure:**
```
✗ Authentication failed

Error: <error message from CLI>

To fix: /bedrock:diagnose for detailed troubleshooting
```
