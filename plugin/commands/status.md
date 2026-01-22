---
description: Quick Bedrock status check
---

# /bedrock:status

Quick status check for AWS Bedrock configuration.

## Run Diagnostics

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js test-bedrock
```

```bash
node ${CLAUDE_PLUGIN_ROOT}/scripts/dist/index.js check-prerequisites
```

## Display Results

**If not configured (`configured: false`):**

```
Bedrock Status: Not configured

Run /bedrock:manage to set up AWS Bedrock.
```

**If configured:**

The `test-bedrock` command returns `sessionExpiresLocal` (formatted in local time with timezone).

Display:
```
Bedrock Status
============================================

  Profile:  <profile>
  Region:   <region>
  Model:    <model>
  Auth:     <✓ valid | ✗ expired>
  Expires:  <sessionExpiresLocal> (e.g., "2026-01-22 04:55 MST")

System
  [OK] AWS CLI installed (<version>)
  [OK] Node installed (<version>)

Authentication
  [OK/FAIL] <credentials.message>

Access
  [OK/FAIL] <bedrockAccess.message>
  [OK/FAIL] <modelAvailable.message>

Status: <All checks passed | X issue(s) detected>
```

**If issues detected**, suggest:
- Auth expired → "Run `/bedrock:refresh` to re-authenticate"
- Other issues → "Run `/bedrock:manage` for more options"
