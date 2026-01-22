#!/usr/bin/env bash
# Auto-approve READ-ONLY bash commands used by the Bedrock plugin
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
   [[ "$COMMAND" == *'which jq'* ]] || \
   [[ "$COMMAND" == *'jq --version'* ]] || \
   [[ "$COMMAND" == *'aws sts get-caller-identity'* ]] || \
   [[ "$COMMAND" == *'aws configure list-profiles'* ]] || \
   [[ "$COMMAND" == *'aws configure get '* ]] || \
   [[ "$COMMAND" == *'aws configure export-credentials'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-inference-profiles'* ]] || \
   [[ "$COMMAND" == *'aws bedrock list-foundation-models'* ]]; then

    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Bedrock plugin read-only command"
  }
}
EOF
    exit 0
fi

# Commands requiring user approval (not auto-approved):
# - aws configure sso (modifies config)
# - aws sso login (opens browser)
# - brew install (installs software)

# For any other command, don't make a decision (let normal flow proceed)
echo '{}'
exit 0
