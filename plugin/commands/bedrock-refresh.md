---
description: Re-authenticate your AWS Bedrock SSO session
---

# Bedrock Refresh

Re-authenticate the AWS SSO session.

## Check Current Config

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

**If `configured: false`:**
```
Bedrock not configured

To set up AWS Bedrock: /bedrock
```

## Confirm with User

Use `AskUserQuestion`:
- "Re-authenticate AWS Bedrock? This will open your browser."
- Options: "Yes, open browser" / "Cancel"

## Run SSO Login

Get the profile from the test-bedrock response, then run:

```bash
aws sso login --profile <profile>
```

**Note:** This command opens a browser and requires user interaction. It cannot be auto-approved.

**Output:**
```
Re-authenticating AWS Bedrock
Profile: <profile>

Opening browser for SSO login...
```

## Verify Success

After login completes, run test-bedrock again to verify:

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

**If `allPassed: true`:**
```
✓ Authentication successful

Your SSO session is now active.
```

**If `credentials.passed: false`:**
```
✗ Authentication may not have completed

Try running /bedrock:refresh again or check /bedrock:diagnose
```

## Error Handling

| Error | Fix |
|-------|-----|
| Profile not found | Run `/bedrock` to reconfigure |
| SSO login cancelled | Run `/bedrock:refresh` again |
| Network error | Check internet/VPN connection |
| SSO portal unreachable | Verify SSO URL, run `/bedrock` to reconfigure |
