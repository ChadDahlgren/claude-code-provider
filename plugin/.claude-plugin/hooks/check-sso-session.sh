#!/usr/bin/env bash
#
# SessionStart hook: Check AWS SSO session status before conversation begins
#
# Uses AWS CLI to check session validity - no manual file parsing needed.
# This runs BEFORE the AI conversation starts, so even if the CLI makes
# API calls, we can catch failures and warn the user.
#
# Output: JSON with additionalContext if session is expired/expiring
#

set -euo pipefail

# Configuration
WARNING_THRESHOLD_MINUTES=30

# Check if Bedrock is configured and get the profile name
get_bedrock_profile() {
    # Check environment variable first
    if [[ -n "${AWS_PROFILE:-}" ]] && [[ "${CLAUDE_CODE_USE_BEDROCK:-}" == "1" ]]; then
        echo "$AWS_PROFILE"
        return 0
    fi

    # Check settings.json
    if [[ -f ~/.claude/settings.json ]] && command -v jq &> /dev/null; then
        local use_bedrock=$(jq -r '.env.CLAUDE_CODE_USE_BEDROCK // ""' ~/.claude/settings.json 2>/dev/null)
        local profile=$(jq -r '.env.AWS_PROFILE // ""' ~/.claude/settings.json 2>/dev/null)
        if [[ "$use_bedrock" == "1" ]] && [[ -n "$profile" ]]; then
            echo "$profile"
            return 0
        fi
    fi

    return 1
}

# Check if profile uses SSO Session format (has refresh tokens)
check_has_sso_session() {
    local profile="$1"

    # Use AWS CLI to check if profile references an sso_session
    local sso_session
    sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null || echo "")

    if [[ -n "$sso_session" ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

# Get credentials and check session status using AWS CLI
check_session_via_cli() {
    local profile="$1"

    # Try to export credentials - this will fail if session is expired
    local result
    local exit_code

    result=$(aws configure export-credentials --profile "$profile" --format process 2>&1)
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        # Session is expired or invalid
        echo "expired:$result"
        return 0
    fi

    # Session is valid - check expiration time
    if ! command -v jq &> /dev/null; then
        echo "valid:unknown"
        return 0
    fi

    local expiration
    expiration=$(echo "$result" | jq -r '.Expiration // ""' 2>/dev/null)

    if [[ -z "$expiration" ]]; then
        echo "valid:unknown"
        return 0
    fi

    # Calculate minutes until expiration
    local expires_epoch now_epoch diff_seconds diff_minutes

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Convert ISO8601 to epoch
        expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${expiration%%[+-]*}" "+%s" 2>/dev/null || echo "0")
    else
        # GNU date
        expires_epoch=$(date -d "$expiration" "+%s" 2>/dev/null || echo "0")
    fi

    if [[ "$expires_epoch" == "0" ]]; then
        echo "valid:unknown"
        return 0
    fi

    now_epoch=$(date "+%s")
    diff_seconds=$((expires_epoch - now_epoch))
    diff_minutes=$((diff_seconds / 60))

    if [[ $diff_minutes -lt $WARNING_THRESHOLD_MINUTES ]]; then
        echo "expiring:$diff_minutes"
    else
        echo "valid:$diff_minutes"
    fi
}

# Main logic
main() {
    # Check if Bedrock is configured
    local profile
    if ! profile=$(get_bedrock_profile); then
        # Not using Bedrock, nothing to check
        echo '{}'
        exit 0
    fi

    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        cat << 'EOF'
{
  "hookSpecificOutput": {
    "additionalContext": "WARNING: AWS CLI not found. Cannot check SSO session status.\n\nInstall with: brew install awscli"
  }
}
EOF
        exit 0
    fi

    # Check session status via CLI
    local status
    status=$(check_session_via_cli "$profile")

    # Check if profile has refresh tokens (SSO Session format)
    local has_sso_session
    has_sso_session=$(check_has_sso_session "$profile")

    case "$status" in
        expired:*)
            local error_msg="${status#expired:}"
            cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "WARNING: Your AWS SSO session is expired or invalid. Claude Code cannot connect to Bedrock.\n\nTo fix, run: aws sso login --profile $profile\n\nOr use: /bedrock:refresh"
  }
}
EOF
            ;;
        expiring:*)
            local minutes="${status#expiring:}"
            cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "NOTE: Your AWS SSO session expires in $minutes minutes. Consider refreshing soon with: /bedrock:refresh"
  }
}
EOF
            ;;
        valid:*)
            # Session is valid - check if using legacy format (no refresh tokens)
            if [[ "$has_sso_session" == "no" ]]; then
                local minutes="${status#valid:}"
                if [[ "$minutes" != "unknown" ]]; then
                    local hours=$((minutes / 60))
                    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "TIP: Your SSO session is valid (~${hours}h remaining) but uses legacy format.\n\nThis means you must re-authenticate every ~8 hours. To enable 90-day sessions:\n1. Run: aws configure sso\n2. When prompted for 'SSO registration scopes', enter: sso:account:access\n\nSee /bedrock for guided setup."
  }
}
EOF
                else
                    # Valid but can't determine time, and no refresh tokens
                    cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "TIP: Your SSO profile uses legacy format without refresh tokens.\n\nThis means you must re-authenticate every ~8 hours. To enable 90-day sessions:\n1. Run: aws configure sso\n2. When prompted for 'SSO registration scopes', enter: sso:account:access"
  }
}
EOF
                fi
            else
                # All good - valid session with SSO Session format
                echo '{}'
            fi
            ;;
        *)
            # Unknown status, silently continue
            echo '{}'
            ;;
    esac
}

main
