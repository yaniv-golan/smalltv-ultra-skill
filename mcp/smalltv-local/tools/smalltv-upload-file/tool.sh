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

file_path="$(mcp_args_require '.file_path')"
dir="$(mcp_args_require '.dir')"

if [ ! -f "${file_path}" ]; then
  mcp_fail_invalid_args "file not found: ${file_path}"
fi
if [ ! -r "${file_path}" ]; then
  mcp_fail_invalid_args "file not readable: ${file_path}"
fi

ext="${file_path##*.}"
ext_lower="$(printf '%s' "${ext}" | tr '[:upper:]' '[:lower:]')"
case "${ext_lower}" in
  jpg|jpeg|gif) ;;
  bin|gz)
    mcp_fail_invalid_args \
      "Firmware uploads are not supported. Use the web console at http://${device_ip}/update"
    ;;
  *)
    mcp_fail_invalid_args \
      "Unsupported file type '.${ext}'. Only .jpg, .jpeg, and .gif are allowed."
    ;;
esac

case "${dir}" in
  /image/|/gif) ;;
  *)
    mcp_fail_invalid_args \
      "dir must be '/image/' or '/gif', got '${dir}'"
    ;;
esac

url="http://${device_ip}/doUpload?dir=${dir}"
filename="$(basename "${file_path}")"

response="$(curl -sS \
  -X POST \
  -F "file=@${file_path}" \
  --max-time 30 \
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
  --arg dir "${dir}" \
  --arg body "${body_text}" \
  --argjson status_code "${status_code}" \
  '{
    device_ip: $device_ip,
    uploaded_file: $filename,
    target_dir: $dir,
    status_code: $status_code,
    body: $body
  }')"

mcp_result_success "${result}"
