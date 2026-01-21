#!/bin/bash
#
# Reset Bedrock configuration for testing the setup flow
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Resetting Bedrock Configuration ==="
echo ""

"$SCRIPT_DIR/reset-aws-bedrock.sh"
