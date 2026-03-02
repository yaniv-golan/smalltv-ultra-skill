#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "${MCP_SDK:?MCP_SDK environment variable not set}/tool-sdk.sh"

device_ip="$(mcp_args_get '.device_ip // ""' 2>/dev/null || true)"
if [ -z "${device_ip}" ]; then
  device_ip="${SMALLTV_DEVICE_IP:-}"
fi
if [ -z "${device_ip}" ]; then
  mcp_fail_invalid_args "device_ip is required (arg or SMALLTV_DEVICE_IP env var)"
fi

url="http://${device_ip}/v.json"
body="$(curl -fsS --max-time 5 "${url}" 2>/dev/null || true)"
if [ -z "${body}" ]; then
  mcp_result_error "$(mcp_json_obj \
    type "upstream_unreachable" \
    message "Could not reach ${url}")"
  exit 0
fi

if ! printf '%s' "${body}" | "${MCPBASH_JSON_TOOL_BIN:?}" -e . >/dev/null 2>&1; then
  mcp_result_error "$(mcp_json_obj \
    type "invalid_response" \
    message "Device returned non-JSON from /v.json")"
  exit 0
fi

result="$("${MCPBASH_JSON_TOOL_BIN:?}" -cn \
  --arg device_ip "${device_ip}" \
  --arg endpoint "/v.json" \
  --argjson body "${body}" \
  '{device_ip: $device_ip, endpoint: $endpoint, body: $body}')"

mcp_result_success "${result}"
