#!/bin/bash
# setup-claude-bedrock.sh
# Basic bash script to set up Claude Code with AWS Bedrock
# For a nicer TUI experience, use setup-claude-bedrock-tui.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared core library
source "$SCRIPT_DIR/lib/core.sh"

# =============================================================================
# Command-line Arguments
# =============================================================================

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Set up Claude Code to use AWS Bedrock.

Options:
  --disable     Disable Bedrock and revert to Anthropic API
  --help, -h    Show this help message

Examples:
  $(basename "$0")           # Run interactive setup
  $(basename "$0") --disable # Disable Bedrock integration
EOF
}

# Store arguments for later processing (after functions are defined)
ARGS=("$@")

# =============================================================================
# UI Helpers (Basic Bash)
# =============================================================================

print_header() {
  echo ""
  echo "============================================================"
  echo "  $1"
  echo "============================================================"
  echo ""
}

print_step() {
  echo ""
  echo ">> $1"
  echo ""
}

print_success() {
  echo "   [OK] $1"
}

print_warning() {
  echo "   [!] $1"
}

print_error() {
  echo "   [ERROR] $1"
}

print_info() {
  echo "   $1"
}

# Prompt for yes/no
confirm() {
  local prompt="$1"
  local response
  while true; do
    read -rp "$prompt [y/n]: " response
    case "$response" in
      [yY]|[yY][eE][sS]) return 0 ;;
      [nN]|[nN][oO]) return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

# Prompt for input with default
prompt_input() {
  local prompt="$1"
  local default="${2:-}"
  local response

  if [[ -n "$default" ]]; then
    read -rp "$prompt [$default]: " response </dev/tty
    echo "${response:-$default}"
  else
    read -rp "$prompt: " response </dev/tty
    echo "$response"
  fi
}

# Select from a list
select_option() {
  local prompt="$1"
  shift
  local options=("$@")

  # Send menu display to stderr so it shows when output is captured
  echo "$prompt" >&2
  echo "" >&2
  local i=1
  for opt in "${options[@]}"; do
    echo "  $i) $opt" >&2
    ((i++))
  done
  echo "" >&2

  local selection
  while true; do
    read -rp "Enter number (1-${#options[@]}): " selection </dev/tty
    if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#options[@]} )); then
      # Only the result goes to stdout
      echo "${options[$((selection-1))]}"
      return 0
    fi
    echo "Invalid selection. Please try again." >&2
  done
}

# =============================================================================
# Disable Bedrock Function
# =============================================================================

disable_bedrock() {
  print_header "Disable Bedrock Integration"

  if ! is_bedrock_enabled; then
    print_info "Bedrock is not currently enabled."
    exit 0
  fi

  print_info "This will remove Bedrock configuration from Claude Code."
  print_info "Claude will revert to using the Anthropic API directly."
  echo ""

  if confirm "Disable Bedrock integration?"; then
    if remove_bedrock_settings; then
      print_success "Bedrock configuration removed"
      print_info "Claude Code will now use the Anthropic API."
      print_info "You'll need an ANTHROPIC_API_KEY in your environment or settings."
      echo ""
      print_info "Backup saved to: ${CLAUDE_SETTINGS_FILE}.backup"
    else
      print_error "Failed to remove Bedrock settings"
      exit 1
    fi
  else
    print_info "Cancelled."
  fi
}

# =============================================================================
# Parse Command-line Arguments (after functions are defined)
# =============================================================================

if [[ ${#ARGS[@]} -gt 0 ]]; then
  set -- "${ARGS[@]}"
fi
while [[ $# -gt 0 ]]; do
  case "$1" in
    --disable)
      disable_bedrock
      exit 0
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
  shift
done

# =============================================================================
# SSO Scope Configuration
# =============================================================================

check_and_configure_sso_scope() {
  local profile="$1"

  # Get current SSO session info
  local info
  info=$(get_sso_session_info "$profile")
  local session_name format has_scope
  IFS='|' read -r session_name format has_scope <<< "$info"

  # Determine current state
  local current_type=""
  if [[ "$format" == "none" ]]; then
    # Not an SSO profile at all - nothing to configure
    print_info "Profile does not use SSO authentication"
    return
  elif [[ "$format" == "legacy" ]]; then
    current_type="8-hour sessions (legacy format)"
  elif [[ "$has_scope" == "true" ]]; then
    current_type="90-day sessions (refresh tokens)"
  else
    current_type="8-hour sessions (missing scope)"
  fi

  print_info "Current SSO configuration: $current_type"
  echo ""

  # Ask which they want
  local choice
  choice=$(select_option "Which session duration would you like?" \
    "90-day sessions (recommended - less frequent logins)" \
    "8-hour sessions (current default)")

  if [[ "$choice" == *"90-day"* ]]; then
    # They want 90-day sessions
    if [[ "$has_scope" == "true" ]]; then
      print_success "Already configured for 90-day sessions"
    elif [[ "$format" == "legacy" ]]; then
      print_info "Converting to modern SSO format with 90-day sessions..."
      if convert_legacy_to_modern "$profile"; then
        print_success "Updated to 90-day sessions"
        print_info "You'll need to re-authenticate: aws sso login --profile $profile"
        echo ""
        if confirm "Run SSO login now?"; then
          run_sso_login "$profile"
        fi
      else
        print_warning "Could not automatically update. Please update ~/.aws/config manually."
        print_info "Add 'sso_registration_scopes = sso:account:access' to your sso-session block"
      fi
    else
      # Modern format but missing scope
      print_info "Adding refresh token scope..."
      if fix_sso_session_scope "$profile"; then
        print_success "Updated to 90-day sessions"
        print_info "You'll need to re-authenticate: aws sso login --profile $profile"
        echo ""
        if confirm "Run SSO login now?"; then
          run_sso_login "$profile"
        fi
      else
        print_warning "Could not automatically update. Please update ~/.aws/config manually."
        print_info "Add 'sso_registration_scopes = sso:account:access' to your sso-session block"
      fi
    fi
  else
    # They want 8-hour sessions (or keep current)
    print_info "Keeping current session configuration"
  fi
}

# =============================================================================
# Main Setup Flow
# =============================================================================

main() {
  print_header "Claude Code + AWS Bedrock Setup"

  echo "This script will help you set up Claude Code to use AWS Bedrock."
  echo "You'll need:"
  echo "  - Your AWS SSO URL (from your IT team)"
  echo "  - A few minutes to complete browser authentication"
  echo ""

  if ! confirm "Ready to begin?"; then
    echo "Setup cancelled."
    exit 0
  fi

  # -------------------------------------------------------------------------
  # Step 1: Check Prerequisites
  # -------------------------------------------------------------------------
  print_step "Step 1: Checking prerequisites..."

  # Homebrew (macOS only)
  if [[ "$(uname)" == "Darwin" ]]; then
    if check_homebrew; then
      print_success "Homebrew installed"
    else
      print_warning "Homebrew not found"
      if confirm "Install Homebrew?"; then
        install_homebrew
        print_success "Homebrew installed"
      else
        print_error "Homebrew is required on macOS. Exiting."
        exit 1
      fi
    fi
  fi

  # AWS CLI
  if check_aws_cli; then
    print_success "AWS CLI v2 installed"
  else
    print_warning "AWS CLI v2 not found"
    if confirm "Install AWS CLI?"; then
      install_aws_cli
      print_success "AWS CLI installed"
    else
      print_error "AWS CLI is required. Exiting."
      exit 1
    fi
  fi

  # Claude Code
  if check_claude_code; then
    print_success "Claude Code installed"
  else
    print_warning "Claude Code not found"
    if confirm "Install Claude Code?"; then
      install_claude_code
      print_success "Claude Code installed"

      # Source shell config to get claude in PATH
      local shell_rc
      shell_rc=$(get_shell_rc)
      if [[ -f "$shell_rc" ]]; then
        print_info "Sourcing $shell_rc to update PATH..."
        # shellcheck disable=SC1090
        source "$shell_rc" 2>/dev/null || true
      fi
    else
      print_error "Claude Code is required. Exiting."
      exit 1
    fi
  fi

  # -------------------------------------------------------------------------
  # Step 2: AWS Profile Setup
  # -------------------------------------------------------------------------
  print_step "Step 2: Configuring AWS profile..."

  local profiles
  profiles=$(get_aws_profiles)

  local selected_profile=""
  local selected_region=""

  if [[ -n "$profiles" ]]; then
    print_info "Found existing AWS profiles."
    echo ""

    local profile_array
    IFS=$'\n' read -rd '' -a profile_array <<<"$profiles" || true

    local choice
    choice=$(select_option "Would you like to:" "Use an existing profile" "Configure a new profile")

    if [[ "$choice" == "Use an existing profile" ]]; then
      # Show profiles and let them select
      selected_profile=$(select_option "Select a profile:" "${profile_array[@]}")
      print_info "Selected profile: $selected_profile"

      # Check if credentials are valid
      print_info "Checking credentials..."
      if ! check_profile_credentials "$selected_profile"; then
        print_warning "Credentials expired or invalid. Running SSO login..."
        run_sso_login "$selected_profile"
      else
        print_success "Credentials valid"
      fi

      # Check SSO session format and offer to configure
      check_and_configure_sso_scope "$selected_profile"

      # Get/verify region
      selected_region=$(get_profile_region "$selected_profile")
      if [[ -z "$selected_region" ]]; then
        selected_region=$(prompt_input "Enter AWS region" "us-west-2")
      else
        print_info "Profile region: $selected_region"
      fi

    else
      # Configure new profile
      setup_new_profile
      # This will set selected_profile and selected_region
    fi
  else
    print_info "No AWS profiles found. Let's configure one."
    setup_new_profile
  fi

  # -------------------------------------------------------------------------
  # Step 3: Verify Bedrock Access
  # -------------------------------------------------------------------------
  print_step "Step 3: Verifying Bedrock access..."

  if check_bedrock_access "$selected_profile" "$selected_region"; then
    print_success "Bedrock access confirmed in $selected_region"
  else
    print_warning "Bedrock not accessible in $selected_region"
    print_info "Searching for a region with Bedrock access..."

    local found_region
    found_region=$(find_bedrock_region "$selected_profile") || true

    if [[ -n "$found_region" ]]; then
      print_info "Found Bedrock access in: $found_region"
      if confirm "Use $found_region instead?"; then
        selected_region="$found_region"
      else
        print_error "Cannot proceed without Bedrock access."
        exit 1
      fi
    else
      print_error "Could not find Bedrock access in any region."
      print_info "Please contact your AWS administrator to enable Bedrock access."
      exit 1
    fi
  fi

  # -------------------------------------------------------------------------
  # Step 4: Configure Claude Code
  # -------------------------------------------------------------------------
  print_step "Step 4: Configuring Claude Code..."

  print_info "Setting up with:"
  print_info "  Profile: $selected_profile"
  print_info "  Region: $selected_region"
  print_info "  Model: Claude Opus 4.5 (global)"
  print_info "  Fast Model: Claude Sonnet 4.5 (global)"
  print_info "  Thinking Tokens: 12,000"
  print_info "  Output Tokens: 10,000"
  echo ""

  if confirm "Apply these settings?"; then
    write_claude_settings \
      "$selected_profile" \
      "$selected_region" \
      "$DEFAULT_MODEL" \
      "$DEFAULT_FAST_MODEL" \
      "$DEFAULT_THINKING_TOKENS" \
      "$DEFAULT_OUTPUT_TOKENS"

    print_success "Settings written to $CLAUDE_SETTINGS_FILE"
  else
    print_info "Setup cancelled."
    exit 0
  fi

  # -------------------------------------------------------------------------
  # Step 5: Final Instructions
  # -------------------------------------------------------------------------
  print_success_message
  print_run_instructions

  echo "============================================================"
  echo ""
}

# =============================================================================
# New Profile Setup (Subroutine)
# =============================================================================

setup_new_profile() {
  echo ""
  print_info "We'll now run 'aws configure sso' to set up your AWS profile."
  echo ""
  echo "------------------------------------------------------------"
  echo "  When prompted, use these values:"
  echo ""
  echo "    SSO session name:          bedrock"
  echo "    SSO registration scopes:   sso:account:access"
  echo ""
  echo "  The scope gives you 90-day sessions instead of 8-hour."
  echo "  The session name can be anything you like."
  echo "------------------------------------------------------------"
  echo ""

  if ! confirm "Ready to start AWS SSO configuration?"; then
    print_info "Setup cancelled."
    exit 0
  fi

  echo ""
  # Run aws configure sso interactively
  aws configure sso

  echo ""
  print_success "SSO configuration complete"
  echo ""

  # Now ask which profile they created/want to use
  local profiles
  profiles=$(get_aws_profiles)

  if [[ -z "$profiles" ]]; then
    print_error "No profiles found after configuration. Please try again."
    exit 1
  fi

  local profile_array
  IFS=$'\n' read -rd '' -a profile_array <<<"$profiles" || true

  selected_profile=$(select_option "Which profile did you just configure?" "${profile_array[@]}")
  print_info "Using profile: $selected_profile"

  # Get the region
  selected_region=$(get_profile_region "$selected_profile")
  if [[ -z "$selected_region" ]]; then
    selected_region=$(prompt_input "Enter the AWS region for Bedrock" "us-west-2")
    aws configure set region "$selected_region" --profile "$selected_profile"
  fi
}

# =============================================================================
# Run Main
# =============================================================================

main "$@"
