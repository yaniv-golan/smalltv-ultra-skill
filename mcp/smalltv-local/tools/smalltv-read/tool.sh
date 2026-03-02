#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "${MCP_SDK:?MCP_SDK environment variable not set}/tool-sdk.sh"

device_ip="$(mcp_args_get '.device_ip // ""' 2>/dev/null || true)"
if [ -z "${device_ip}" ]; then
  device_ip="${SMALLTV_IP:-}"
fi
if [ -z "${device_ip}" ]; then
  mcp_fail_invalid_args \
    "device_ip is required (pass as argument or set SMALLTV_IP env var)"
fi

path="$(mcp_args_require '.path')"

if [ -z "${path}" ] || [ "${path#"/"}" = "${path}" ]; then
  mcp_fail_invalid_args "path must start with '/'"
fi

case "${path}" in
  /set|/set\?*|/wifisave*|/delete*|/update*|/doUpload*)
    mcp_fail_invalid_args \
      "This is a write endpoint. Use smalltv-write instead."
    ;;
esac

url="http://${device_ip}${path}"

response_body="$(curl -sS \
  -X GET \
  --max-time 8 \
  --write-out '%{http_code}' \
  --output - \
  "${url}" 2>/dev/null || true)"

if [ -z "${response_body}" ]; then
  mcp_result_error "$(mcp_json_obj \
    type "upstream_unreachable" \
    message "Could not reach ${url}")"
  exit 0
fi

status_code="${response_body: -3}"
body_text="${response_body::-3}"

if ! printf '%s' "${status_code}" | grep -Eq '^[0-9]{3}$'; then
  mcp_result_error "$(mcp_json_obj \
    type "invalid_response" \
    message "Unexpected curl response format for ${url}")"
  exit 0
fi

result="$("${MCPBASH_JSON_TOOL_BIN:?}" -cn \
  --arg device_ip "${device_ip}" \
  --arg path "${path}" \
  --arg body "${body_text}" \
  --argjson status_code "${status_code}" \
  '{
    device_ip: $device_ip,
    request: { method: "GET", path: $path },
    status_code: $status_code,
    body: $body
  }')"

mcp_result_success "${result}"
