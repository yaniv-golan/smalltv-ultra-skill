#!/usr/bin/env bash
set -euo pipefail

INSTALL_MCP_BASH="false"
CLIENT_NAME="cursor"
DEVICE_IP="${SMALLTV_DEVICE_IP:-}"
MCP_BASH_VERSION="v1.1.2"

usage() {
  cat <<'EOF'
Usage: ./setup.sh [options]

Options:
  --install-mcp-bash    Auto-install mcp-bash if missing
  --client NAME         MCP client for config output (default: cursor)
  --device-ip IP        Export SMALLTV_DEVICE_IP for this run
  -h, --help            Show this help message

Examples:
  ./setup.sh
  ./setup.sh --install-mcp-bash --client cursor --device-ip 192.168.5.253
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-mcp-bash)
      INSTALL_MCP_BASH="true"
      ;;
    --client)
      if [ "$#" -lt 2 ]; then
        echo "Error: --client requires a value." >&2
        exit 1
      fi
      CLIENT_NAME="$2"
      shift
      ;;
    --device-ip)
      if [ "$#" -lt 2 ]; then
        echo "Error: --device-ip requires a value." >&2
        exit 1
      fi
      DEVICE_IP="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if ! command -v jq >/dev/null 2>&1 && ! command -v gojq >/dev/null 2>&1; then
  echo "Warning: jq/gojq not found. Install one for full mcp-bash functionality." >&2
fi

if ! command -v mcp-bash >/dev/null 2>&1; then
  if [ "${INSTALL_MCP_BASH}" = "true" ]; then
    echo "Installing mcp-bash ${MCP_BASH_VERSION}..."
    curl -fsSL "https://raw.githubusercontent.com/yaniv-golan/mcp-bash-framework/${MCP_BASH_VERSION}/install.sh" \
      | bash -s -- --yes --version "${MCP_BASH_VERSION}"
    export PATH="${HOME}/.local/bin:${PATH}"
  else
    cat <<'EOF' >&2
mcp-bash is not installed.

Install it manually:
  curl -fsSL "https://raw.githubusercontent.com/yaniv-golan/mcp-bash-framework/v1.1.2/install.sh" | bash -s -- --yes --version "v1.1.2"

Or run this script with:
  ./setup.sh --install-mcp-bash
EOF
    exit 1
  fi
fi

if ! command -v mcp-bash >/dev/null 2>&1; then
  echo "Error: mcp-bash still not found on PATH after install." >&2
  exit 1
fi

if [ -n "${DEVICE_IP}" ]; then
  export SMALLTV_DEVICE_IP="${DEVICE_IP}"
fi

echo "Setup complete."
if [ -n "${SMALLTV_DEVICE_IP:-}" ]; then
  echo "Using SMALLTV_DEVICE_IP=${SMALLTV_DEVICE_IP}"
else
  echo "SMALLTV_DEVICE_IP is not set. Set it before using tools."
fi
echo
echo "Next step: generate MCP client config snippet"
echo "  cd ${SCRIPT_DIR}"
echo "  mcp-bash config --client ${CLIENT_NAME}"
