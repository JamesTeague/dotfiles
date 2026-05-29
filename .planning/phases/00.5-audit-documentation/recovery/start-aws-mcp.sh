#!/usr/bin/env bash
#
# AWS MCP Server Launcher
#
# This script automatically starts the AWS API MCP (Model Context Protocol) server
# with proper environment setup and credential management.
#
# Purpose:
# - Creates and manages a Python virtual environment for the AWS MCP server
# - Installs/updates the awslabs.aws-api-mcp-server package
# - Handles AWS SSO authentication for the specified profile
# - Launches the MCP server with proper logging
#
# Usage:
#   start-aws-mcp.sh [-p profile]
#
# Examples:
#   start-aws-mcp.sh                    # Use default AWS profile
#   start-aws-mcp.sh -p production      # Use 'production' AWS profile
#   start-aws-mcp.sh -p dev-account     # Use 'dev-account' AWS profile
#
# Prerequisites:
# - AWS CLI installed and configured with SSO profiles
# - Python 3 available on PATH
# - Internet access for package installation
#
# The server will run in the foreground and log to ~/.mcp/logs/aws-api-mcp.YYYYMMDD.log
#
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") [-p profile]" >&2
  echo "  -p profile   AWS CLI profile (SSO) to use (default: default)" >&2
}

PROFILE="default"
while getopts ":p:h" opt; do
  case $opt in
    p) PROFILE="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument" >&2; usage; exit 2 ;;
    \?) echo "Invalid option -$OPTARG" >&2; usage; exit 2 ;;
  esac
done
shift $((OPTIND-1))

# ----- Configuration -----
SERVER_PKG="awslabs.aws-api-mcp-server"   # latest each start (no pin)
VENV_DIR="${HOME}/.mcp/envs/aws-api-mcp"
LOG_DIR="${HOME}/.mcp/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/aws-api-mcp.$(date +%Y%m%d).log"

log() { printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"; }

log "--- wrapper start (profile=$PROFILE) pid=$$ ---"

# Find python3
if command -v python3 >/dev/null 2>&1; then
  PYBIN=$(command -v python3)
elif command -v python >/dev/null 2>&1; then
  PYBIN=$(command -v python)
else
  log "ERROR: python3 not found on PATH"
  echo "python3 not found; cannot start AWS MCP server" >&2
  exit 127
fi

# Create venv if missing
if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  log "Creating virtualenv at ${VENV_DIR}"
  mkdir -p "$(dirname "$VENV_DIR")"
  "$PYBIN" -m venv "$VENV_DIR" || { log "ERROR: venv creation failed"; echo "venv creation failed" >&2; exit 1; }
  "${VENV_DIR}/bin/python" -m pip install --upgrade --quiet pip || log "WARN: pip upgrade failed"
fi

VPY="${VENV_DIR}/bin/python"

# Ensure package present (latest each run; could add caching heuristic if needed)
if ! "$VPY" -c "import awslabs.aws_api_mcp_server" 2>/dev/null; then
  log "Installing $SERVER_PKG (initial)"
  "$VPY" -m pip install --quiet "$SERVER_PKG" || { log "ERROR: initial install failed"; echo "Server package install failed" >&2; exit 1; }
else
  # Attempt a lightweight upgrade check (non-fatal if offline)
  log "Upgrading $SERVER_PKG (attempt)"
  "$VPY" -m pip install --quiet --upgrade "$SERVER_PKG" || log "WARN: upgrade attempt failed"
fi

log "Ensuring SSO credentials for profile=$PROFILE"
if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  log "Triggering aws sso login for $PROFILE"
  aws sso login --profile "$PROFILE" || { log "ERROR: aws sso login failed"; echo "aws sso login failed" >&2; exit 1; }
fi

export AWS_PROFILE="$PROFILE"
export AWS_SDK_LOAD_CONFIG=1

log "Launching server via console script"
exec "${VENV_DIR}/bin/awslabs.aws-api-mcp-server" 2>>"$LOG_FILE"

