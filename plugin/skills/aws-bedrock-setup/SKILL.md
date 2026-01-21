# AWS Bedrock Reference

Reference material for configuring Claude Code with AWS Bedrock.

## Supported Regions

| Region | Location | Notes |
|--------|----------|-------|
| us-west-2 | Oregon | **Recommended** - best availability |
| us-east-1 | N. Virginia | Good availability |
| eu-west-1 | Ireland | For European users |
| eu-central-1 | Frankfurt | For European users |
| ap-northeast-1 | Tokyo | For Asia-Pacific |
| ap-southeast-2 | Sydney | For Australia/NZ |

## Inference Profiles (CRITICAL for Claude 4.5)

Claude 4.5 models require **inference profiles**. You cannot use the raw model ID.

**Error without inference profile:**
```
400 Invocation of model ID anthropic.claude-opus-4-5-20251101-v1:0 with on-demand throughput isn't supported.
```

**Solution:** Add region prefix to model ID:

| Prefix | Coverage |
|--------|----------|
| `us.` | US cross-region |
| `eu.` | EU cross-region |
| `apac.` | Asia-Pacific |

**Example:**
```
# Wrong (won't work for Claude 4.5)
anthropic.claude-opus-4-5-20251101-v1:0

# Correct (inference profile)
us.anthropic.claude-opus-4-5-20251101-v1:0
```

**Query available inference profiles:**
```bash
aws bedrock list-inference-profiles --region us-west-2 --output json | \
  jq -r '.inferenceProfileSummaries[] | select(.inferenceProfileArn | contains("anthropic")) | [.inferenceProfileId, .inferenceProfileName] | @tsv'
```

Always use the exact IDs returned by AWS.

## AWS SSO Configuration

### SSO Start URL Format
```
https://{company-identifier}.awsapps.com/start
```

### Interactive Setup Flow
```bash
aws configure sso
```

Prompts for:
1. SSO session name (e.g., `work-dev`)
2. SSO start URL (your company's SSO portal)
3. SSO region (usually `us-east-1`)
4. SSO registration scopes (accept default)
5. *Browser auth - user selects account/role*
6. Default client region (e.g., `us-west-2`)
7. Default output format (`json`)
8. CLI profile name (e.g., `work-dev`)

### SSO Login
```bash
aws sso login --profile <profile-name>
```

Opens browser for authentication. Session lasts ~12 hours.

## Required IAM Permissions

Minimum:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:ListFoundationModels",
      "bedrock:ListInferenceProfiles"
    ],
    "Resource": "*"
  }]
}
```

Or use AWS managed policy: `AmazonBedrockFullAccess`

## Claude Code Configuration

**Settings file:** `~/.claude/settings.json`

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "CLAUDE_CODE_USE_VERTEX": "0",
    "AWS_PROFILE": "my-profile-name",
    "AWS_REGION": "us-west-2",
    "ANTHROPIC_MODEL": "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
  },
  "bedrockAuthRefresh": "aws sso login --profile my-profile-name"
}
```

**Critical values:**
- `CLAUDE_CODE_USE_BEDROCK`: Must be `"1"` (string)
- `ANTHROPIC_MODEL`: Use inference profile ID for Claude 4.5

**Always merge, never overwrite** - users may have MCP servers, hooks, etc.

## Common Issues

### Token Expired
```bash
aws sso login --profile <profile>
```

### Profile Not Found
```bash
aws configure list-profiles  # List available
aws configure sso --profile <name>  # Create new
```

### Access Denied
IAM role lacks Bedrock permissions. Ask administrator to attach `AmazonBedrockFullAccess` or custom policy.

### Model Not Available
- Check region supports the model
- Use inference profile format for Claude 4.5
- Query available models: `aws bedrock list-inference-profiles --region <region>`

## AWS CLI Installation

**macOS:**
```bash
brew install awscli
```

**Verify:**
```bash
aws --version
```

## Useful Commands

```bash
# List profiles
aws configure list-profiles

# Check session
aws sts get-caller-identity --profile <profile>

# List Claude models
aws bedrock list-inference-profiles --region us-west-2 --output json | \
  jq '.inferenceProfileSummaries[] | select(.inferenceProfileArn | contains("anthropic"))'

# Login
aws sso login --profile <profile>

# Logout all sessions
aws sso logout
```

## Resources

- [AWS Bedrock](https://aws.amazon.com/bedrock/)
- [Claude on Bedrock](https://docs.anthropic.com/claude/docs/bedrock)
- [AWS CLI](https://aws.amazon.com/cli/)
