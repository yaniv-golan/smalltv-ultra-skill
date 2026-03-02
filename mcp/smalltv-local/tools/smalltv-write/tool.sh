#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "${MCP_SDK:?MCP_SDK environment variable not set}/tool-sdk.sh"

device_ip="$(mcp_args_get '.device_ip // ""' 2>/dev/null || true)"
if [ -z "${device_ip}" ]; then
  device_ip="${SMALLTV_DEVICE_IP:-}"
fi
if [ -z "${device_ip}" ]; then
  mcp_fail_invalid_args \
    "device_ip is required (arg or SMALLTV_DEVICE_IP env var)"
fi

method="$(mcp_args_get '.method // "GET"' 2>/dev/null || true)"
path="$(mcp_args_require '.path')"
body="$(mcp_args_get '.body // ""' 2>/dev/null || true)"
content_type="$(mcp_args_get '.content_type // "application/json"' \
  2>/dev/null || true)"

if [ -z "${path}" ] || [ "${path#"/"}" = "${path}" ]; then
  mcp_fail_invalid_args "path must start with '/'"
fi

url="http://${device_ip}${path}"

if [ -n "${body}" ]; then
  response_body="$(curl -sS \
    -X "${method}" \
    -H "Content-Type: ${content_type}" \
    --data-raw "${body}" \
    --max-time 8 \
    --write-out '%{http_code}' \
    --output - \
    "${url}" 2>/dev/null || true)"
else
  response_body="$(curl -sS \
    -X "${method}" \
    --max-time 8 \
    --write-out '%{http_code}' \
    --output - \
    "${url}" 2>/dev/null || true)"
fi

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
  --arg method "${method}" \
  --arg path "${path}" \
  --arg content_type "${content_type}" \
  --arg body "${body_text}" \
  --argjson status_code "${status_code}" \
  '{
    device_ip: $device_ip,
    request: {
      method: $method,
      path: $path,
      content_type: $content_type
    },
    status_code: $status_code,
    body: $body
  }')"

mcp_result_success "${result}"
