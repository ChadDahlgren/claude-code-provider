---
description: Show current AWS Bedrock configuration and authentication status
---

# Bedrock Status

Show the current AWS Bedrock configuration and authentication status.

## Check Status

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

**Response format:**
```json
{
  "success": true,
  "data": {
    "configured": true,
    "profile": "profile-name",
    "region": "us-west-2",
    "model": "global.anthropic.claude-opus-4-5-20251101-v1:0",
    "checks": {
      "credentials": { "passed": true, "message": "Authenticated as arn:aws:..." },
      "bedrockAccess": { "passed": true, "message": "Access to 53 inference profile(s)" },
      "modelAvailable": { "passed": true, "message": "Model ... is available" }
    },
    "allPassed": true
  }
}
```

## Display Based on Response

**If `configured: false`:**
```
Bedrock Status
────────────────────────────────────────────

Not configured

AWS Bedrock is not set up.

To configure: /bedrock
```

**If `allPassed: true`:**
```
Bedrock Status
────────────────────────────────────────────

  Profile:  <profile>
  Region:   <region>
  Model:    <model>
  Auth:     ✓ valid

Commands: /bedrock:diagnose • /bedrock:refresh • /bedrock:reset
```

**If `allPassed: false`:**
```
Bedrock Status
────────────────────────────────────────────

  Profile:  <profile>
  Region:   <region>
  Model:    <model>

Issues detected:
```

Then show each check that has `passed: false` with its `message`.

**Common issues:**
- `credentials.passed: false` → Run `/bedrock:refresh`
- `bedrockAccess.passed: false` → Check IAM permissions
- `modelAvailable.passed: false` → Model may have been removed, run `/bedrock` to reconfigure
