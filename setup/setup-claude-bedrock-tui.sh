#!/bin/bash
# setup-claude-bedrock-tui.sh
# TUI version using gum for a polished interactive experience
# Falls back to basic prompts if gum is not available

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

Set up Claude Code to use AWS Bedrock (TUI version with gum).

Options:
  --disable     Disable Bedrock and revert to Anthropic API
  --help, -h    Show this help message

Examples:
  $(basename "$0")           # Run interactive setup
  $(basename "$0") --disable # Disable Bedrock integration
EOF
}

disable_bedrock_tui() {
  if ! check_gum; then
    echo "gum not installed, falling back to basic script..."
    exec "$SCRIPT_DIR/setup-claude-bedrock.sh" --disable
  fi

  clear
  gum style \
    --border double \
    --border-foreground "#7C3AED" \
    --padding "1 3" \
    --margin "1" \
    --bold \
    "Disable Bedrock Integration"

  if ! is_bedrock_enabled; then
    gum style --foreground "#94A3B8" "   Bedrock is not currently enabled."
    exit 0
  fi

  gum style --foreground "#94A3B8" "This will remove Bedrock configuration from Claude Code."
  gum style --foreground "#94A3B8" "Claude will revert to using the Anthropic API directly."
  echo ""

  if gum confirm "Disable Bedrock integration?"; then
    if remove_bedrock_settings; then
      gum style --foreground "#22C55E" "   [OK] Bedrock configuration removed"
      gum style --foreground "#94A3B8" "   Claude Code will now use the Anthropic API."
      gum style --foreground "#94A3B8" "   You'll need an ANTHROPIC_API_KEY in your environment or settings."
      echo ""
      gum style --faint "   Backup saved to: ${CLAUDE_SETTINGS_FILE}.backup"
    else
      gum style --foreground "#EF4444" "   [ERROR] Failed to remove Bedrock settings"
      exit 1
    fi
  else
    gum style --foreground "#94A3B8" "   Cancelled."
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --disable)
      disable_bedrock_tui
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
# Gum Theme Configuration
# =============================================================================

export GUM_CONFIRM_PROMPT_FOREGROUND="#7C3AED"
export GUM_CHOOSE_CURSOR_FOREGROUND="#7C3AED"
export GUM_CHOOSE_SELECTED_FOREGROUND="#7C3AED"
export GUM_INPUT_CURSOR_FOREGROUND="#7C3AED"
export GUM_INPUT_PROMPT_FOREGROUND="#7C3AED"
export GUM_SPIN_SPINNER_FOREGROUND="#7C3AED"

# =============================================================================
# UI Helpers (Gum)
# =============================================================================

print_header() {
  echo ""
  gum style \
    --border double \
    --border-foreground "#7C3AED" \
    --padding "1 3" \
    --margin "1" \
    --bold \
    "$1"
  echo ""
}

print_step() {
  echo ""
  gum style --foreground "#7C3AED" --bold ">> $1"
  echo ""
}

print_success() {
  gum style --foreground "#22C55E" "   [OK] $1"
}

print_warning() {
  gum style --foreground "#F59E0B" "   [!] $1"
}

print_error() {
  gum style --foreground "#EF4444" "   [ERROR] $1"
}

print_info() {
  gum style --foreground "#94A3B8" "   $1"
}

# Prompt for yes/no with gum
confirm() {
  local prompt="$1"
  gum confirm "$prompt"
}

# Prompt for input with gum
prompt_input() {
  local prompt="$1"
  local default="${2:-}"
  local placeholder="${3:-}"

  if [[ -n "$default" ]]; then
    gum input --prompt "$prompt: " --value "$default" --placeholder "$placeholder"
  else
    gum input --prompt "$prompt: " --placeholder "$placeholder"
  fi
}

# Select from a list with gum
select_option() {
  local prompt="$1"
  shift
  local options=("$@")

  echo ""
  gum style --foreground "#94A3B8" "$prompt"
  echo ""
  gum choose "${options[@]}"
}

# Show a spinner while running a command
with_spinner() {
  local message="$1"
  shift
  gum spin --spinner dot --title "$message" -- "$@"
}

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
    if [[ "$has_scope" == "true" ]]; then
      print_success "Already configured for 90-day sessions"
    elif [[ "$format" == "legacy" ]]; then
      print_info "Converting to modern SSO format with 90-day sessions..."
      if convert_legacy_to_modern "$profile"; then
        print_success "Updated to 90-day sessions"
        print_info "You'll need to re-authenticate"
        echo ""
        if confirm "Run SSO login now?"; then
          gum style --foreground "#F59E0B" "   A browser window will open for authentication."
          run_sso_login "$profile"
        fi
      else
        print_warning "Could not automatically update."
        gum style --faint "   Add 'sso_registration_scopes = sso:account:access' to your sso-session block"
      fi
    else
      print_info "Adding refresh token scope..."
      if fix_sso_session_scope "$profile"; then
        print_success "Updated to 90-day sessions"
        print_info "You'll need to re-authenticate"
        echo ""
        if confirm "Run SSO login now?"; then
          gum style --foreground "#F59E0B" "   A browser window will open for authentication."
          run_sso_login "$profile"
        fi
      else
        print_warning "Could not automatically update."
        gum style --faint "   Add 'sso_registration_scopes = sso:account:access' to your sso-session block"
      fi
    fi
  else
    print_info "Keeping current session configuration"
  fi
}

# =============================================================================
# Main Setup Flow
# =============================================================================

main() {
  # Check for gum first
  if ! check_gum; then
    echo ""
    echo "This script requires 'gum' for the TUI experience."
    echo ""
    if [[ "$(uname)" == "Darwin" ]]; then
      read -rp "Install gum via Homebrew? [y/n]: " response
      if [[ "$response" =~ ^[yY] ]]; then
        echo "Installing gum..."
        brew install gum
      else
        echo ""
        echo "You can use the basic version instead: ./setup-claude-bedrock.sh"
        exit 1
      fi
    else
      echo "Please install gum: https://github.com/charmbracelet/gum#installation"
      echo "Or use the basic version: ./setup-claude-bedrock.sh"
      exit 1
    fi
  fi

  clear
  print_header "Claude Code + AWS Bedrock Setup"

  gum style --foreground "#94A3B8" "This script will help you set up Claude Code to use AWS Bedrock."
  echo ""
  gum style --foreground "#94A3B8" "You'll need:"
  gum style --foreground "#94A3B8" "  - Your AWS SSO URL (from your IT team)"
  gum style --foreground "#94A3B8" "  - A few minutes to complete browser authentication"
  echo ""

  if ! confirm "Ready to begin?"; then
    gum style --foreground "#94A3B8" "Setup cancelled."
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
        gum spin --spinner dot --title "Installing Homebrew..." -- bash -c 'install_homebrew'
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
      gum spin --spinner dot --title "Installing AWS CLI..." -- bash -c 'install_aws_cli'
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
      gum spin --spinner dot --title "Installing Claude Code..." -- bash -c 'install_claude_code'
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
        echo ""
        gum style --foreground "#F59E0B" "   A browser window will open for authentication."
        echo ""
        run_sso_login "$selected_profile"
      else
        print_success "Credentials valid"
      fi

      # Check SSO session format and offer to configure
      check_and_configure_sso_scope "$selected_profile"

      # Get/verify region
      selected_region=$(get_profile_region "$selected_profile")
      if [[ -z "$selected_region" ]]; then
        selected_region=$(prompt_input "Enter AWS region" "us-west-2" "e.g., us-west-2")
      else
        print_info "Profile region: $selected_region"
      fi

    else
      # Configure new profile
      setup_new_profile
    fi
  else
    print_info "No AWS profiles found. Let's configure one."
    setup_new_profile
  fi

  # -------------------------------------------------------------------------
  # Step 3: Verify Bedrock Access
  # -------------------------------------------------------------------------
  print_step "Step 3: Verifying Bedrock access..."

  local bedrock_ok=false

  gum spin --spinner dot --title "Checking Bedrock access in $selected_region..." -- bash -c "
    source '$SCRIPT_DIR/lib/core.sh'
    check_bedrock_access '$selected_profile' '$selected_region'
  " && bedrock_ok=true || bedrock_ok=false

  if $bedrock_ok; then
    print_success "Bedrock access confirmed in $selected_region"
  else
    print_warning "Bedrock not accessible in $selected_region"
    print_info "Searching for a region with Bedrock access..."

    local found_region=""
    for region in "${BEDROCK_REGIONS[@]}"; do
      if gum spin --spinner dot --title "Trying $region..." -- bash -c "
        source '$SCRIPT_DIR/lib/core.sh'
        check_bedrock_access '$selected_profile' '$region'
      " 2>/dev/null; then
        found_region="$region"
        break
      fi
    done

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

  echo ""
  gum style --border normal --border-foreground "#7C3AED" --padding "1 2" --margin "0 2" "
$(gum style --bold 'Configuration Summary')

  Profile:         $selected_profile
  Region:          $selected_region
  Model:           Claude Opus 4.5 (global)
  Fast Model:      Claude Sonnet 4.5 (global)
  Thinking Tokens: 12,000
  Output Tokens:   10,000
"
  echo ""

  if confirm "Apply these settings?"; then
    gum spin --spinner dot --title "Writing configuration..." -- bash -c "
      source '$SCRIPT_DIR/lib/core.sh'
      write_claude_settings \
        '$selected_profile' \
        '$selected_region' \
        '$DEFAULT_MODEL' \
        '$DEFAULT_FAST_MODEL' \
        '$DEFAULT_THINKING_TOKENS' \
        '$DEFAULT_OUTPUT_TOKENS'
    "

    print_success "Settings written to $CLAUDE_SETTINGS_FILE"
  else
    print_info "Setup cancelled."
    exit 0
  fi

  # -------------------------------------------------------------------------
  # Step 5: Final Instructions
  # -------------------------------------------------------------------------
  echo ""
  gum style \
    --border double \
    --border-foreground "#22C55E" \
    --padding "1 3" \
    --margin "1" \
    "$(gum style --bold --foreground '#22C55E' 'Claude Code is configured for AWS Bedrock!')"

  echo ""
  gum style --foreground "#94A3B8" "Quick tips:"
  echo ""
  gum style --foreground "#94A3B8" "  Thinking tokens (12,000): Controls reasoning depth."
  gum style --faint "    - Range: 4,096 - 16,384"
  gum style --faint "    - Lower = faster, simpler responses"
  gum style --faint "    - Higher = deeper analysis (may over-engineer simple tasks)"
  echo ""
  gum style --foreground "#94A3B8" "  Output tokens (10,000): Maximum response length."
  gum style --faint "    - Range: 4,096 - 16,384"
  gum style --faint "    - Increase if responses feel cut off"
  echo ""
  gum style --faint "  Edit ~/.claude/settings.json to adjust these values."
  echo ""
  gum style --bold --foreground "#7C3AED" "  Run 'claude' to get started!"
  echo ""
}

# =============================================================================
# New Profile Setup (Subroutine)
# =============================================================================

setup_new_profile() {
  echo ""
  gum style --foreground "#94A3B8" "We'll now run 'aws configure sso' to set up your AWS profile."
  echo ""
  gum style \
    --border normal \
    --border-foreground "#F59E0B" \
    --padding "1 2" \
    --margin "0 2" \
    "$(gum style --bold --foreground '#F59E0B' 'When prompted, use these values:')

  SSO session name:          $(gum style --bold 'bedrock')
  SSO registration scopes:   $(gum style --bold 'sso:account:access')

The scope gives you 90-day sessions instead of 8-hour.
The session name can be anything you like."
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
    selected_region=$(prompt_input "Enter the AWS region for Bedrock" "us-west-2" "e.g., us-west-2")
    aws configure set region "$selected_region" --profile "$selected_profile"
  fi
}

# =============================================================================
# Run Main
# =============================================================================

main "$@"
