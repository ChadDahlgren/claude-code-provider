#!/bin/bash
# setup/lib/core.sh
# Shared functions for Claude Code Bedrock setup scripts

set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
CLAUDE_SETTINGS_DIR="$HOME/.claude"

# Default model configurations (global inference profiles)
DEFAULT_MODEL="global.anthropic.claude-opus-4-5-20251101-v1:0"
DEFAULT_FAST_MODEL="global.anthropic.claude-sonnet-4-5-20250929-v1:0"

# Default token settings
DEFAULT_THINKING_TOKENS="12000"
DEFAULT_OUTPUT_TOKENS="10000"

# Known Bedrock regions (in preference order)
BEDROCK_REGIONS=(
  "us-west-2"
  "us-east-1"
  "eu-west-1"
  "ap-northeast-1"
  "ap-southeast-2"
)

# =============================================================================
# Utility Functions
# =============================================================================

# Check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Get the current shell rc file
get_shell_rc() {
  case "$SHELL" in
    */zsh)  echo "$HOME/.zshrc" ;;
    */bash) echo "$HOME/.bashrc" ;;
    *)      echo "$HOME/.profile" ;;
  esac
}

# =============================================================================
# Prerequisite Checks
# =============================================================================

# Check if Homebrew is installed (macOS only)
check_homebrew() {
  if [[ "$(uname)" != "Darwin" ]]; then
    return 0  # Not macOS, skip
  fi

  if command_exists brew; then
    return 0
  fi
  return 1
}

# Install Homebrew
install_homebrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add to PATH for Apple Silicon
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

# Check if AWS CLI v2 is installed
check_aws_cli() {
  if ! command_exists aws; then
    return 1
  fi

  # Verify it's v2
  local version
  version=$(aws --version 2>&1 | grep -oE 'aws-cli/[0-9]+' | cut -d/ -f2)
  if [[ "$version" -lt 2 ]]; then
    return 1
  fi
  return 0
}

# Install AWS CLI
install_aws_cli() {
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install awscli
  else
    # Linux - use official installer
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
  fi
}

# Check if Claude Code is installed
check_claude_code() {
  command_exists claude
}

# Install Claude Code
install_claude_code() {
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install claude-code
  else
    npm install -g @anthropic-ai/claude-code
  fi
}

# Check if gum is installed (for TUI version)
check_gum() {
  command_exists gum
}

# Install gum
install_gum() {
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install gum
  else
    # Linux - check for package managers
    if command_exists apt-get; then
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
      echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
      sudo apt update && sudo apt install gum
    elif command_exists yum; then
      echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
      sudo yum install gum
    else
      echo "Please install gum manually: https://github.com/charmbracelet/gum#installation"
      return 1
    fi
  fi
}

# =============================================================================
# AWS Profile Functions
# =============================================================================

# Get list of AWS profiles
get_aws_profiles() {
  aws configure list-profiles 2>/dev/null || echo ""
}

# Get the region for a profile
get_profile_region() {
  local profile="$1"
  aws configure get region --profile "$profile" 2>/dev/null || echo ""
}

# Check if profile has valid credentials
check_profile_credentials() {
  local profile="$1"
  aws sts get-caller-identity --profile "$profile" &>/dev/null
}

# Get credential expiration for a profile
get_credential_expiration() {
  local profile="$1"
  local creds
  creds=$(aws configure export-credentials --profile "$profile" --format env 2>/dev/null) || return 1

  # Extract expiration from the output
  echo "$creds" | grep -oE 'AWS_CREDENTIAL_EXPIRATION=[^ ]+' | cut -d= -f2 | tr -d "'"
}

# Check if profile uses SSO session format (for refresh tokens)
# Returns:
#   0 = Has correct scope (90-day sessions)
#   1 = Missing scope or legacy format
check_sso_session_format() {
  local profile="$1"
  local config_file="$HOME/.aws/config"

  if [[ ! -f "$config_file" ]]; then
    return 1
  fi

  # Check if profile references an sso_session
  local sso_session
  sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null) || return 1

  if [[ -z "$sso_session" ]]; then
    return 1  # Legacy format (no sso_session reference)
  fi

  # Check if the sso-session has the right scope
  local scope
  scope=$(grep -A5 "^\[sso-session $sso_session\]" "$config_file" 2>/dev/null | grep "sso_registration_scopes" | head -1) || return 1

  if [[ "$scope" == *"sso:account:access"* ]]; then
    return 0  # Has refresh token scope
  fi

  return 1  # Missing scope
}

# Get detailed SSO session info for a profile
# Outputs: session_name|format|has_scope
# format: "modern" (uses sso-session) or "legacy" (inline sso config)
# has_scope: "true" or "false"
get_sso_session_info() {
  local profile="$1"
  local config_file="$HOME/.aws/config"

  if [[ ! -f "$config_file" ]]; then
    echo "|none|false"
    return
  fi

  # Check if profile references an sso_session
  local sso_session
  sso_session=$(aws configure get sso_session --profile "$profile" 2>/dev/null) || sso_session=""

  if [[ -z "$sso_session" ]]; then
    # Check if it's legacy SSO (has sso_start_url directly in profile)
    local sso_url
    sso_url=$(aws configure get sso_start_url --profile "$profile" 2>/dev/null) || sso_url=""
    if [[ -n "$sso_url" ]]; then
      echo "|legacy|false"
    else
      echo "|none|false"
    fi
    return
  fi

  # Modern format - check scope
  local scope_line
  scope_line=$(grep -A10 "^\[sso-session $sso_session\]" "$config_file" 2>/dev/null | grep "sso_registration_scopes" | head -1) || scope_line=""

  if [[ "$scope_line" == *"sso:account:access"* ]]; then
    echo "$sso_session|modern|true"
  else
    echo "$sso_session|modern|false"
  fi
}

# Add or update SSO registration scope for a session
# Returns 0 on success, 1 on failure
fix_sso_session_scope() {
  local profile="$1"
  local config_file="$HOME/.aws/config"

  if [[ ! -f "$config_file" ]]; then
    return 1
  fi

  # Get session info
  local info
  info=$(get_sso_session_info "$profile")
  local session_name format has_scope
  IFS='|' read -r session_name format has_scope <<< "$info"

  if [[ "$format" == "legacy" ]]; then
    # Legacy format - need to convert to modern format
    # This is more complex, return failure and let caller handle
    return 2  # Special code for "needs conversion"
  fi

  if [[ "$format" == "none" ]]; then
    return 1  # Not an SSO profile
  fi

  if [[ "$has_scope" == "true" ]]; then
    return 0  # Already has correct scope
  fi

  # Modern format without scope - add it
  # Backup the config first
  cp "$config_file" "${config_file}.backup"

  # Check if sso_registration_scopes line exists (but with wrong value)
  if grep -q "^\[sso-session $session_name\]" "$config_file"; then
    # Find the sso-session block and check for existing scope line
    local in_session=false
    local found_scope=false
    local temp_file="${config_file}.tmp"

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ ^\[sso-session\ $session_name\] ]]; then
        in_session=true
        echo "$line" >> "$temp_file"
      elif [[ "$line" =~ ^\[.*\] ]]; then
        # New section starting
        if $in_session && ! $found_scope; then
          # Add scope before the new section
          echo "sso_registration_scopes = sso:account:access" >> "$temp_file"
        fi
        in_session=false
        echo "$line" >> "$temp_file"
      elif $in_session && [[ "$line" =~ ^sso_registration_scopes ]]; then
        # Replace existing scope line
        echo "sso_registration_scopes = sso:account:access" >> "$temp_file"
        found_scope=true
      else
        echo "$line" >> "$temp_file"
      fi
    done < "$config_file"

    # If we ended while still in the session and didn't find scope, add it
    if $in_session && ! $found_scope; then
      echo "sso_registration_scopes = sso:account:access" >> "$temp_file"
    fi

    mv "$temp_file" "$config_file"
  fi

  return 0
}

# Convert legacy SSO profile to modern sso-session format
convert_legacy_to_modern() {
  local profile="$1"
  local config_file="$HOME/.aws/config"

  # Get the legacy SSO settings
  local sso_url sso_region sso_account sso_role region
  sso_url=$(aws configure get sso_start_url --profile "$profile" 2>/dev/null) || return 1
  sso_region=$(aws configure get sso_region --profile "$profile" 2>/dev/null) || sso_region="us-east-1"
  sso_account=$(aws configure get sso_account_id --profile "$profile" 2>/dev/null) || sso_account=""
  sso_role=$(aws configure get sso_role_name --profile "$profile" 2>/dev/null) || sso_role=""
  region=$(aws configure get region --profile "$profile" 2>/dev/null) || region=""

  if [[ -z "$sso_url" ]]; then
    return 1
  fi

  # Backup
  cp "$config_file" "${config_file}.backup"

  # Create session name from profile
  local session_name="${profile}-session"

  # Check if session already exists
  if grep -q "^\[sso-session $session_name\]" "$config_file"; then
    # Session exists, just update profile to reference it
    :
  else
    # Add the sso-session block at the end
    cat >> "$config_file" <<EOF

[sso-session $session_name]
sso_start_url = $sso_url
sso_region = $sso_region
sso_registration_scopes = sso:account:access
EOF
  fi

  # Now update the profile to use the session instead of inline settings
  # Remove old sso_ settings and add sso_session reference
  local temp_file="${config_file}.tmp"
  local in_profile=false
  local wrote_session=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^\[profile\ $profile\] ]]; then
      in_profile=true
      echo "$line" >> "$temp_file"
    elif [[ "$line" =~ ^\[.*\] ]]; then
      in_profile=false
      echo "$line" >> "$temp_file"
    elif $in_profile; then
      # Skip old sso_ lines (except sso_account_id and sso_role_name)
      if [[ "$line" =~ ^sso_start_url ]] || [[ "$line" =~ ^sso_region ]]; then
        if ! $wrote_session; then
          echo "sso_session = $session_name" >> "$temp_file"
          wrote_session=true
        fi
        # Skip this line
      else
        echo "$line" >> "$temp_file"
      fi
    else
      echo "$line" >> "$temp_file"
    fi
  done < "$config_file"

  mv "$temp_file" "$config_file"
  return 0
}

# Get SSO session name for a profile (if using session format)
get_sso_session_name() {
  local profile="$1"
  aws configure get sso_session --profile "$profile" 2>/dev/null || echo ""
}

# Check if profile has Bedrock access
check_bedrock_access() {
  local profile="$1"
  local region="${2:-}"

  # If no region provided, get it from the profile
  if [[ -z "$region" ]]; then
    region=$(get_profile_region "$profile")
  fi

  if [[ -z "$region" ]]; then
    return 1
  fi

  aws bedrock list-inference-profiles \
    --profile "$profile" \
    --region "$region" \
    --max-results 1 \
    &>/dev/null
}

# Find a working Bedrock region for a profile
find_bedrock_region() {
  local profile="$1"
  local profile_region
  profile_region=$(get_profile_region "$profile")

  # Try profile's region first
  if [[ -n "$profile_region" ]] && check_bedrock_access "$profile" "$profile_region"; then
    echo "$profile_region"
    return 0
  fi

  # Try known Bedrock regions
  for region in "${BEDROCK_REGIONS[@]}"; do
    if check_bedrock_access "$profile" "$region"; then
      echo "$region"
      return 0
    fi
  done

  return 1
}

# List available Claude models for a profile/region
list_claude_models() {
  local profile="$1"
  local region="$2"

  aws bedrock list-inference-profiles \
    --profile "$profile" \
    --region "$region" \
    --query "inferenceProfileSummaries[?contains(inferenceProfileId, 'anthropic.claude')].inferenceProfileId" \
    --output text 2>/dev/null | tr '\t' '\n' | grep "^global\." | sort -u
}

# =============================================================================
# SSO Configuration
# =============================================================================

# Run SSO login for a profile
run_sso_login() {
  local profile="$1"
  aws sso login --profile "$profile"
}

# Configure a new SSO profile
# This outputs the commands/guidance - actual execution depends on the UI
configure_sso_profile() {
  local sso_url="$1"
  local profile_name="$2"
  local sso_region="${3:-us-east-1}"

  # Create the sso-session block
  local session_name="${profile_name}-session"

  cat <<EOF

Add the following to ~/.aws/config:

[sso-session $session_name]
sso_start_url = $sso_url
sso_region = $sso_region
sso_registration_scopes = sso:account:access

[profile $profile_name]
sso_session = $session_name
sso_account_id = <your-account-id>
sso_role_name = <your-role-name>
region = us-west-2

Then run: aws sso login --profile $profile_name

EOF
}

# =============================================================================
# Claude Code Configuration
# =============================================================================

# Read current Claude settings
read_claude_settings() {
  if [[ -f "$CLAUDE_SETTINGS_FILE" ]]; then
    cat "$CLAUDE_SETTINGS_FILE"
  else
    echo "{}"
  fi
}

# Write Claude settings (merges with existing)
write_claude_settings() {
  local profile="$1"
  local region="$2"
  local model="${3:-$DEFAULT_MODEL}"
  local fast_model="${4:-$DEFAULT_FAST_MODEL}"
  local thinking_tokens="${5:-$DEFAULT_THINKING_TOKENS}"
  local output_tokens="${6:-$DEFAULT_OUTPUT_TOKENS}"

  # Ensure directory exists
  mkdir -p "$CLAUDE_SETTINGS_DIR"

  # Build the settings JSON
  local settings
  settings=$(cat <<EOF
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",

    "AWS_PROFILE": "$profile",
    "AWS_REGION": "$region",

    "ANTHROPIC_MODEL": "$model",
    "CLAUDE_CODE_FAST_MODEL": "$fast_model",

    "MAX_THINKING_TOKENS": "$thinking_tokens",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "$output_tokens",
    "DISABLE_PROMPT_CACHING": "0"
  }
}
EOF
)

  # If settings file exists, merge (preserving non-env keys)
  if [[ -f "$CLAUDE_SETTINGS_FILE" ]]; then
    # Backup existing
    cp "$CLAUDE_SETTINGS_FILE" "${CLAUDE_SETTINGS_FILE}.backup"

    # Merge using jq if available, otherwise overwrite
    if command_exists jq; then
      local existing
      existing=$(cat "$CLAUDE_SETTINGS_FILE")
      echo "$existing" | jq --argjson new "$settings" '. * $new' > "${CLAUDE_SETTINGS_FILE}.tmp"
      mv "${CLAUDE_SETTINGS_FILE}.tmp" "$CLAUDE_SETTINGS_FILE"
    else
      echo "$settings" > "$CLAUDE_SETTINGS_FILE"
    fi
  else
    echo "$settings" > "$CLAUDE_SETTINGS_FILE"
  fi
}

# Remove Bedrock configuration from Claude settings
# This removes all Bedrock-related env vars, reverting to Anthropic API mode
remove_bedrock_settings() {
  if [[ ! -f "$CLAUDE_SETTINGS_FILE" ]]; then
    return 0
  fi

  # Backup existing
  cp "$CLAUDE_SETTINGS_FILE" "${CLAUDE_SETTINGS_FILE}.backup"

  if command_exists jq; then
    local existing
    existing=$(cat "$CLAUDE_SETTINGS_FILE")
    # Remove all Bedrock-related env vars - this reverts to Anthropic API
    echo "$existing" | jq 'del(.env.CLAUDE_CODE_USE_BEDROCK, .env.AWS_PROFILE, .env.AWS_REGION, .env.ANTHROPIC_MODEL, .env.CLAUDE_CODE_FAST_MODEL, .env.MAX_THINKING_TOKENS, .env.CLAUDE_CODE_MAX_OUTPUT_TOKENS, .env.DISABLE_PROMPT_CACHING)' > "${CLAUDE_SETTINGS_FILE}.tmp"
    mv "${CLAUDE_SETTINGS_FILE}.tmp" "$CLAUDE_SETTINGS_FILE"
    return 0
  else
    echo "Warning: jq not installed, cannot cleanly remove settings. Please edit $CLAUDE_SETTINGS_FILE manually."
    return 1
  fi
}

# Check if Bedrock is currently enabled
is_bedrock_enabled() {
  if [[ ! -f "$CLAUDE_SETTINGS_FILE" ]]; then
    return 1
  fi

  if command_exists jq; then
    local use_bedrock
    use_bedrock=$(jq -r '.env.CLAUDE_CODE_USE_BEDROCK // "0"' "$CLAUDE_SETTINGS_FILE" 2>/dev/null)
    [[ "$use_bedrock" == "1" ]]
  else
    grep -q '"CLAUDE_CODE_USE_BEDROCK".*"1"' "$CLAUDE_SETTINGS_FILE" 2>/dev/null
  fi
}

# =============================================================================
# Final Output
# =============================================================================

# Print the final success message and tips
print_success_message() {
  cat <<'EOF'

============================================================
  Claude Code is configured for AWS Bedrock!
============================================================

Quick tips:

  Thinking tokens (12,000): Controls reasoning depth.
    - Range: 4,096 - 16,384
    - Lower = faster, simpler responses
    - Higher = deeper analysis (may over-engineer simple tasks)

  Output tokens (10,000): Maximum response length.
    - Range: 4,096 - 16,384
    - Increase if responses feel cut off

  Edit ~/.claude/settings.json to adjust these values.

------------------------------------------------------------

EOF
}

print_run_instructions() {
  cat <<'EOF'
  Run 'claude' to get started!

EOF
}
