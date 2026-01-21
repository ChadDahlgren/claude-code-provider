---
description: Run diagnostics to identify configuration or authentication issues
---

# Provider Diagnose Command

Run comprehensive diagnostics on the current provider configuration.

## Behavior

1. Read `~/.claude/settings.json` to determine active provider
2. Run checks in order, stop at first critical failure
3. Show clear fix for any issue found

## No Provider Configured

```
No provider configured

Claude Code is using the default Anthropic API.
Nothing to diagnose.

To configure a provider, run: /provider
```

---

## AWS Bedrock Diagnostics

Run these checks in order:

### Check 1: AWS CLI
```bash
which aws && aws --version
```
- ✓ Installed → continue
- ✗ Not installed → "Run /provider to install AWS CLI"

### Check 2: Profile Exists
```bash
aws configure list-profiles | grep -w "<AWS_PROFILE>"
```
- ✓ Found → continue
- ✗ Not found → "Profile not found. Run /provider to reconfigure"

### Check 3: SSO Session
```bash
aws sts get-caller-identity --profile <AWS_PROFILE> 2>&1
```
- ✓ Returns identity → session valid
- ✗ Fails → "Session expired. Run: aws sso login --profile <profile>"

### Check 4: Claude Code Config
Check settings.json has:
- `CLAUDE_CODE_USE_BEDROCK`: `"1"`
- `AWS_PROFILE`: set
- `AWS_REGION`: set

### Output (All Pass)
```
Running diagnostics...

System
  ✓ AWS CLI installed
  ✓ Profile exists (<profile>)

Authentication
  ✓ SSO session valid

Claude Code
  ✓ Bedrock mode enabled
  ✓ Profile configured
  ✓ Region configured

✓ All checks passed
```

### Output (Issue Found)
```
Running diagnostics...

System
  ✓ AWS CLI installed
  ✓ Profile exists (cricut-dev)

Authentication
  ✗ SSO session expired

To fix: aws sso login --profile cricut-dev

Or: /provider:refresh
```

---

## Google Vertex AI Diagnostics

Run these checks in order:

### Check 1: gcloud CLI
```bash
which gcloud && gcloud --version | head -1
```
- ✓ Installed → continue
- ✗ Not installed → "Run /provider to install gcloud CLI"

### Check 2: Project Accessible
```bash
gcloud projects describe <GOOGLE_PROJECT_ID> 2>&1
```
- ✓ Returns info → continue
- ✗ Fails → "Project not found or not accessible"

### Check 3: Authentication
```bash
gcloud auth application-default print-access-token 2>&1
```
- ✓ Returns token → authenticated
- ✗ Fails → "Not authenticated. Run: gcloud auth application-default login"

### Check 4: Vertex AI API
```bash
gcloud services list --enabled --filter="name:aiplatform.googleapis.com" --project=<project> 2>&1
```
- ✓ Found → API enabled
- ✗ Not found → "Vertex AI API not enabled. Run: gcloud services enable aiplatform.googleapis.com --project=<project>"

### Check 5: Claude Code Config
Check settings.json has:
- `CLAUDE_CODE_USE_VERTEX`: `"1"`
- `GOOGLE_PROJECT_ID`: set
- `ANTHROPIC_VERTEX_REGION`: set

### Output (All Pass)
```
Running diagnostics...

System
  ✓ gcloud CLI installed
  ✓ Project accessible (<project>)

Authentication
  ✓ Credentials valid

Vertex AI
  ✓ API enabled

Claude Code
  ✓ Vertex AI mode enabled
  ✓ Project configured
  ✓ Region configured

✓ All checks passed
```

### Output (Issue Found)
```
Running diagnostics...

System
  ✓ gcloud CLI installed
  ✓ Project accessible (my-project)

Authentication
  ✗ Not authenticated

To fix: gcloud auth application-default login

Or: /provider:refresh
```
