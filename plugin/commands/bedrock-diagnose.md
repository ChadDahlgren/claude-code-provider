---
description: Run diagnostics to identify AWS Bedrock configuration or authentication issues
---

# Bedrock Diagnose

Run comprehensive diagnostics on the AWS Bedrock configuration.

## Run Diagnostics

Run both checks:

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js check-prerequisites
```

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

## Interpret Results

### Prerequisites Check

```json
{
  "success": true,
  "data": {
    "ready": true,
    "missing": []
  }
}
```

- `ready: false` → Show missing tools, suggest `brew install`

### Bedrock Check

```json
{
  "success": true,
  "data": {
    "configured": true,
    "allPassed": true,
    "checks": {
      "credentials": { "passed": true, "message": "..." },
      "bedrockAccess": { "passed": true, "message": "..." },
      "modelAvailable": { "passed": true, "message": "..." }
    }
  }
}
```

## Display Output

**If not configured:**
```
Bedrock not configured

To set up AWS Bedrock: /bedrock
```

**If all pass:**
```
Running Bedrock diagnostics...

System
  ✓ AWS CLI installed
  ✓ Node installed

Authentication
  ✓ Credentials valid

Access
  ✓ Bedrock access confirmed
  ✓ Model available

✓ All checks passed
```

**If issues found:**
```
Running Bedrock diagnostics...

System
  ✓ AWS CLI installed
  ✓ Node installed

Authentication
  ✗ <credentials.message>

To fix: /bedrock:refresh
```

## Fixes by Issue

| Check Failed | Fix |
|--------------|-----|
| `ready: false` | Install missing tools |
| `credentials.passed: false` | Run `/bedrock:refresh` or `aws sso login --profile <profile>` |
| `bedrockAccess.passed: false` | Check IAM permissions, verify Bedrock is enabled in region |
| `modelAvailable.passed: false` | Model changed or removed, run `/bedrock` to reconfigure |
