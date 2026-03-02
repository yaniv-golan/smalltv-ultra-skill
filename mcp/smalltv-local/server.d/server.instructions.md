# SmallTV Local MCP Server — Instructions

This MCP server provides local HTTP access to a GeekMagic SmallTV Ultra
device on your LAN. The device has **no authentication** — every HTTP
request executes immediately.

## Tool Selection

1. **Always call `smalltv-get-device-info` first** to verify the device
   is reachable and confirm it is a SmallTV-Ultra (not a Pro or other
   model). Do this once per session before any other tool call.
2. Use `smalltv-read` for status queries and config checks — GET-only,
   read-only. Works with `/*.json`, `/filelist?dir=...`, static pages.
   Write endpoints (`/set`, `/wifisave`, `/delete`) are blocked.
3. Use `smalltv-write` to change settings, control display, or run
   system commands. Supports all HTTP methods. Common pattern:
   `GET /set?param=value`.
4. Use `smalltv-upload-file` to upload JPG or GIF images from the local
   filesystem. It handles multipart form data internally. Do **not**
   attempt file uploads through `smalltv-write` — its string body
   cannot carry binary data.
5. Use `smalltv-upload-firmware` only when the user explicitly asks to
   flash firmware. Requires `confirm=true` — always ask the user first.
   Bad firmware can brick the device.

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
- **Never flash firmware** without explicit user approval and
  `confirm=true`.

## Common Endpoint Patterns

Settings use `GET /set?param=value` and return `"OK"` on success.

| Task                | Tool               | Path                         |
|---------------------|--------------------|------------------------------ |
| Check storage       | `smalltv-read`     | `/space.json`                |
| List album files    | `smalltv-read`     | `/filelist?dir=/image/`      |
| Set theme (1-7)     | `smalltv-write`    | `/set?theme={n}`             |
| Set brightness      | `smalltv-write`    | `/set?brt={-10..100}`        |
| Set city            | `smalltv-write`    | `/set?cd1={name}&cd2=1000`   |
| Display image       | `smalltv-write`    | `/set?img=/image/{file}`     |
| Upload image        | `smalltv-upload-file`  | (local file path)        |
| Flash firmware      | `smalltv-upload-firmware` | (local .bin path)     |

## Reference Resources

This server exposes MCP resources with additional documentation:
- `file://./resources/api-reference.md` — full HTTP API and endpoint catalog
- `file://./resources/safety-guide.md` — destructive endpoints and constraints

Consult these resources when you need endpoint details beyond the
common patterns listed above.
