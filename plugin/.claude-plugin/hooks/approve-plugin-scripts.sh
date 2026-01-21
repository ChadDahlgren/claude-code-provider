#!/usr/bin/env bash
# Auto-approve READ-ONLY bash commands used by the provider plugin
# Commands that modify system state require user approval
# This hook receives JSON input on stdin and outputs a decision

set -euo pipefail

# Read the JSON input from Claude Code
INPUT=$(cat)

# Extract the command using jq (more reliable than grep/sed)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

# AWS CLI read-only commands
if [[ "$COMMAND" == *'aws --version'* ]] || \
   [[ "$COMMAND" == *'which aws'* ]] || \
   [[ "$COMMAND" == *'aws sts get-caller-identity'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-inference-profiles'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-foundation-models'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Provider plugin read-only AWS command"
  }
}
EOF
    exit 0
fi

# Google Cloud CLI read-only commands
if [[ "$COMMAND" == *'gcloud --version'* ]] || \
   [[ "$COMMAND" == *'which gcloud'* ]] || \
   [[ "$COMMAND" == *'gcloud auth application-default print-access-token'* ]] || \
   [[ "$COMMAND" == *'gcloud projects list'* ]] || \
   [[ "$COMMAND" == *'gcloud projects describe'* ]] || \
   [[ "$COMMAND" == *'gcloud config get-value'* ]] || \
   [[ "$COMMAND" == *'gcloud services list'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Provider plugin read-only gcloud command"
  }
}
EOF
    exit 0
fi

# Commands requiring user approval (not auto-approved):
# - aws configure list-profiles (reads config)
# - aws configure sso (modifies config)
# - aws sso login (opens browser)
# - gcloud auth application-default login (opens browser)
# - gcloud services enable (modifies project)
# - brew install (installs software)

# For any other command, don't make a decision (let normal flow proceed)
echo '{}'
exit 0
