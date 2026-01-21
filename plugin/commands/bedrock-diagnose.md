---
description: Run diagnostics to identify AWS Bedrock configuration or authentication issues
---

# Bedrock Diagnose

Run comprehensive diagnostics on the AWS Bedrock configuration.

## Behavior

1. Read `~/.claude/settings.json`
2. Run checks in order, stop at first critical failure
3. Show clear fix for any issue found

## Not Configured

```
Bedrock not configured

To set up AWS Bedrock: /bedrock
```

## Diagnostic Checks

Run these checks in order:

### Check 1: AWS CLI

```bash
which aws && aws --version
```

- ✓ Installed → continue
- ✗ Not installed → "AWS CLI not found. Run /bedrock to install."

### Check 2: Profile Exists

```bash
aws configure list-profiles | grep -w "<AWS_PROFILE>"
```

- ✓ Found → continue
- ✗ Not found → "Profile not found. Run /bedrock to reconfigure."

### Check 3: SSO Session

```bash
aws sts get-caller-identity --profile <AWS_PROFILE> 2>&1
```

- ✓ Returns identity → session valid
- ✗ Fails → "Session expired. Run: aws sso login --profile <profile>"

### Check 4: Configuration

Check settings.json has:
- `CLAUDE_CODE_USE_BEDROCK`: `"1"`
- `AWS_PROFILE`: set
- `AWS_REGION`: set
- `ANTHROPIC_MODEL`: set

## Output (All Pass)

```
Running Bedrock diagnostics...

System
  ✓ AWS CLI installed
  ✓ Profile exists (<profile>)

Authentication
  ✓ SSO session valid

Configuration
  ✓ Bedrock enabled
  ✓ Profile configured
  ✓ Region configured
  ✓ Model configured

✓ All checks passed
```

## Output (Issue Found)

```
Running Bedrock diagnostics...

System
  ✓ AWS CLI installed
  ✓ Profile exists (<profile>)

Authentication
  ✗ SSO session expired

To fix: aws sso login --profile <profile>

Or: /bedrock:refresh
```
