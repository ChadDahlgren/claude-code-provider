#!/usr/bin/env bash
#
# SessionStart hook: Check AWS SSO session status before conversation begins
#
# This script checks ~/.aws/sso/cache/ for session expiration and warns the user
# BEFORE the AI conversation starts, avoiding the chicken-and-egg problem where
# expired credentials prevent the AI from helping troubleshoot.
#
# Output: JSON with additionalContext if session is expired/expiring
#

set -euo pipefail

# Configuration
WARNING_THRESHOLD_MINUTES=30

# Check if Bedrock is configured by looking for AWS_PROFILE in environment or settings
check_bedrock_configured() {
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

# Find the SSO cache file for a profile
find_sso_cache() {
    local cache_dir="$HOME/.aws/sso/cache"

    if [[ ! -d "$cache_dir" ]]; then
        return 1
    fi

    # Find the most recent cache file with an accessToken
    for cache_file in "$cache_dir"/*.json; do
        if [[ -f "$cache_file" ]] && command -v jq &> /dev/null; then
            if jq -e '.accessToken and .expiresAt' "$cache_file" &> /dev/null; then
                echo "$cache_file"
                return 0
            fi
        fi
    done

    return 1
}

# Check session status from cache file
check_session_status() {
    local cache_file="$1"

    if ! command -v jq &> /dev/null; then
        echo "jq_missing"
        return 0
    fi

    local expires_at=$(jq -r '.expiresAt // ""' "$cache_file" 2>/dev/null)

    if [[ -z "$expires_at" ]]; then
        echo "no_expiry"
        return 0
    fi

    # Parse the expiration time and compare to now
    # Handle both formats: "2026-01-21T08:25:07Z" and "2026-01-21T08:25:07UTC"
    local expires_epoch
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        expires_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${expires_at%%[A-Z]*}" "+%s" 2>/dev/null || echo "0")
    else
        # GNU date command
        expires_epoch=$(date -d "$expires_at" "+%s" 2>/dev/null || echo "0")
    fi

    local now_epoch=$(date "+%s")
    local diff_seconds=$((expires_epoch - now_epoch))
    local diff_minutes=$((diff_seconds / 60))

    if [[ $diff_seconds -le 0 ]]; then
        echo "expired"
    elif [[ $diff_minutes -lt $WARNING_THRESHOLD_MINUTES ]]; then
        echo "expiring:$diff_minutes"
    else
        echo "valid:$diff_minutes"
    fi
}

# Main logic
main() {
    # Check if Bedrock is configured
    local profile
    if ! profile=$(check_bedrock_configured); then
        # Not using Bedrock, nothing to check
        echo '{}'
        exit 0
    fi

    # Find SSO cache file
    local cache_file
    if ! cache_file=$(find_sso_cache); then
        # No cache file found - session may need login
        cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "WARNING: No AWS SSO session found for profile '$profile'. You may need to authenticate.\n\nRun: aws sso login --profile $profile\n\nOr use: /bedrock:refresh"
  }
}
EOF
        exit 0
    fi

    # Check session status
    local status=$(check_session_status "$cache_file")

    case "$status" in
        expired)
            cat << EOF
{
  "hookSpecificOutput": {
    "additionalContext": "WARNING: Your AWS SSO session has EXPIRED. Claude Code may not be able to connect to Bedrock.\n\nTo fix, run: aws sso login --profile $profile\n\nOr use: /bedrock:refresh"
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
        jq_missing)
            # Can't check without jq, silently continue
            echo '{}'
            ;;
        *)
            # Session is valid, no warning needed
            echo '{}'
            ;;
    esac
}

main
