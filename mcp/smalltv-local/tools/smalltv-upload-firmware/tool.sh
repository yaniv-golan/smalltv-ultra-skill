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

file_path="$(mcp_args_require '.file_path')"
confirm="$(mcp_args_get '.confirm // false' 2>/dev/null || true)"

if [ "${confirm}" != "true" ]; then
  mcp_fail_invalid_args \
    "Firmware upload requires explicit confirmation. Set confirm=true after the user has approved."
fi

if [ ! -f "${file_path}" ]; then
  mcp_fail_invalid_args "file not found: ${file_path}"
fi
if [ ! -r "${file_path}" ]; then
  mcp_fail_invalid_args "file not readable: ${file_path}"
fi

ext="${file_path##*.}"
ext_lower="$(printf '%s' "${ext}" | tr '[:upper:]' '[:lower:]')"
filename="$(basename "${file_path}")"

valid=false
case "${filename}" in
  *.bin.gz) valid=true ;;
esac
if [ "${valid}" != "true" ]; then
  case "${ext_lower}" in
    bin) valid=true ;;
  esac
fi
if [ "${valid}" != "true" ]; then
  mcp_fail_invalid_args \
    "Only .bin and .bin.gz firmware files are accepted, got '${filename}'"
fi

url="http://${device_ip}/update"

response="$(curl -sS \
  -X POST \
  -F "file=@${file_path}" \
  --max-time 120 \
  --write-out '%{http_code}' \
  --output - \
  "${url}" 2>/dev/null || true)"

if [ -z "${response}" ]; then
  mcp_result_error "$(mcp_json_obj \
    type "upstream_unreachable" \
    message "Could not reach ${url}")"
  exit 0
fi

status_code="${response: -3}"
body_text="${response::-3}"

if ! printf '%s' "${status_code}" | grep -Eq '^[0-9]{3}$'; then
  mcp_result_error "$(mcp_json_obj \
    type "invalid_response" \
    message "Unexpected curl response format for ${url}")"
  exit 0
fi

result="$("${MCPBASH_JSON_TOOL_BIN:?}" -cn \
  --arg device_ip "${device_ip}" \
  --arg filename "${filename}" \
  --arg body "${body_text}" \
  --argjson status_code "${status_code}" \
  '{
    device_ip: $device_ip,
    uploaded_file: $filename,
    status_code: $status_code,
    body: $body
  }')"

mcp_result_success "${result}"
