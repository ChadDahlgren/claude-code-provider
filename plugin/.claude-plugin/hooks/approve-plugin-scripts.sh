#!/usr/bin/env bash
# Auto-approve bash commands used by the provider plugin
# This hook receives JSON input on stdin and outputs a decision

set -euo pipefail

# Read the JSON input from Claude Code
INPUT=$(cat)

# Extract the command being run
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//' | sed 's/"$//' || echo "")

# AWS CLI commands used by provider setup/status/diagnose
if [[ "$COMMAND" == *'aws --version'* ]] || \
   [[ "$COMMAND" == *'which aws'* ]] || \
   [[ "$COMMAND" == *'aws configure list-profiles'* ]] || \
   [[ "$COMMAND" == *'aws configure get region'* ]] || \
   [[ "$COMMAND" == *'aws sso login'* ]] || \
   [[ "$COMMAND" == *'aws sts get-caller-identity'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-inference-profiles'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-foundation-models'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Provider plugin AWS command"
  }
}
EOF
    exit 0
fi

# Google Cloud CLI commands used by provider setup/status/diagnose
if [[ "$COMMAND" == *'gcloud --version'* ]] || \
   [[ "$COMMAND" == *'which gcloud'* ]] || \
   [[ "$COMMAND" == *'gcloud auth application-default'* ]] || \
   [[ "$COMMAND" == *'gcloud projects list'* ]] || \
   [[ "$COMMAND" == *'gcloud projects describe'* ]] || \
   [[ "$COMMAND" == *'gcloud config get-value'* ]] || \
   [[ "$COMMAND" == *'gcloud services enable aiplatform'* ]] || \
   [[ "$COMMAND" == *'gcloud services list'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Provider plugin gcloud command"
  }
}
EOF
    exit 0
fi

# Homebrew installs for CLIs
if [[ "$COMMAND" == *'brew install awscli'* ]] || \
   [[ "$COMMAND" == *'brew install google-cloud-sdk'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Provider plugin CLI installation"
  }
}
EOF
    exit 0
fi

# For any other command, don't make a decision (let normal flow proceed)
echo '{}'
exit 0
