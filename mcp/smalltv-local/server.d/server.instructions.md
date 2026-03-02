# SmallTV Local MCP Server — Instructions

This MCP server provides local HTTP access to a GeekMagic SmallTV Ultra
device on your LAN. The device has **no authentication** — every HTTP
request executes immediately.

## Tool Selection

1. **Always call `smalltv-get-device-info` first** to verify the device
   is reachable and confirm it is a SmallTV-Ultra (not a Pro or other
   model). Do this once per session before any other tool call.
2. Use `smalltv-http-request` for settings, status queries, and display
   control (GET/POST with text bodies).
3. Use `smalltv-upload-file` to upload JPG or GIF images from the local
   filesystem. It handles multipart form data internally. Do **not**
   attempt file uploads through `smalltv-http-request` — its string
   body cannot carry binary data.

## Safety Defaults

- Prefer read-only endpoints (`/v.json`, `/space.json`, `/city.json`,
  `/album.json`) before any write operation.
- **Never call destructive endpoints without explicit user intent:**
  - `/wifisave` (empty call wipes WiFi credentials)
  - `/set?reset=1` (factory reset)
  - `/set?reboot=1` (immediate reboot)
  - `/set?clear=image` or `/set?clear=gif` (deletes all uploads)
  - `/delete?file=...` (permanent file deletion)
- Do not probe write endpoints with speculative requests.

## Common Endpoint Patterns

Settings use `GET /set?param=value` and return `"OK"` on success.

| Task                | Path                              |
|---------------------|-----------------------------------|
| Set theme (1-7)     | `/set?theme={n}`                  |
| Set brightness      | `/set?brt={-10..100}`             |
| Set city            | `/set?cd1={name}&cd2=1000`        |
| Check storage       | `/space.json`                     |
| List album files    | `/filelist?dir=/image/`           |
| Upload image        | `smalltv-upload-file` tool        |
| Display image       | `/set?img=/image/{file}`          |
| Switch to album     | `/set?theme=3`                    |

## Reference Resources

This server exposes MCP resources with additional documentation:
- `file://./resources/api-reference.md` — full HTTP API and endpoint catalog
- `file://./resources/safety-guide.md` — destructive endpoints and constraints

Consult these resources when you need endpoint details beyond the
common patterns listed above.
