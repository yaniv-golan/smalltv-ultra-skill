---
name: smalltv-mcp-tools
description: This skill should be used when the SmallTV Local MCP server tools are available and the user asks to "control SmallTV", "read SmallTV status", "upload image to SmallTV", "change SmallTV settings", "flash SmallTV firmware", or interacts with a GeekMagic SmallTV Ultra device through MCP tools (smalltv-get-device-info, smalltv-read, smalltv-write, smalltv-upload-file, smalltv-upload-firmware). Provides tool selection logic, workflows, and safety rules for the MCP-based device control path. Complements the geekmagic-smalltv-ultra skill which covers raw HTTP, alternative firmware, and custom firmware development.
---

# SmallTV MCP Tools

When the **SmallTV Local MCP** server is connected, prefer its tools over raw HTTP (`curl`, Python `requests`). The MCP tools handle connectivity, parameter encoding, multipart uploads, and safety blocking internally.

## MCP Server Identity

- **Server name**: `smalltv-local-mcp`
- **Required config**: `SMALLTV_IP` — the device's LAN IP address
- **Transport**: local (mcp-bash over stdio)

If the MCP tools are not available (server not connected), fall back to the raw HTTP patterns in the **geekmagic-smalltv-ultra** skill.

## Tool Overview

| Tool | Purpose | Safety |
|------|---------|--------|
| `smalltv-get-device-info` | Verify connectivity and model via `/v.json` | Read-only |
| `smalltv-read` | Query status, config, file listings (GET only) | Read-only |
| `smalltv-write` | Change settings, display, system commands | **Write** — some endpoints destructive |
| `smalltv-upload-file` | Upload JPG/GIF from local filesystem | Write (idempotent) |
| `smalltv-upload-firmware` | Flash `.bin` firmware via `/update` | **Destructive** — requires `confirm=true` |

## Tool Selection Rules

1. **Always call `smalltv-get-device-info` first** — once per session, before any other tool. Confirms the device is reachable and is a SmallTV-Ultra (not a Pro or other model).
2. **Use `smalltv-read`** for any status check or data retrieval: `/v.json`, `/space.json`, `/city.json`, `/album.json`, `/filelist?dir=...`, `/wifi.json?q=1`, `/config.json`. Write endpoints (`/set`, `/wifisave`, `/delete`) are blocked by this tool.
3. **Use `smalltv-write`** to change settings or control the display. Common pattern: `path: "/set?param=value"`. Returns `"OK"` on success.
4. **Use `smalltv-upload-file`** for image/GIF uploads. Pass `file_path` (absolute local path) and `dir` (`"/image/"` for album, `"/gif"` for weather GIFs). Do not attempt file uploads through `smalltv-write` — its string body cannot carry binary data.
5. **Use `smalltv-upload-firmware`** only when the user explicitly requests firmware flashing. Always set `confirm: true` only after explicit user approval.

## Common Workflows

### Check device status

```
smalltv-get-device-info  →  confirm model + firmware version
smalltv-read path="/space.json"  →  storage total/free
smalltv-read path="/filelist?dir=/image/"  →  uploaded images
```

### Change a setting

```
smalltv-get-device-info  →  verify device
smalltv-write path="/set?brt=60"  →  set brightness to 60
```

### Upload and display a custom image

```
smalltv-get-device-info  →  verify device
smalltv-read path="/space.json"  →  check free storage
smalltv-upload-file file_path="/tmp/dashboard.jpg" dir="/image/"
smalltv-write path="/set?img=/image/dashboard.jpg"
smalltv-write path="/set?theme=3"  →  switch to Photo Album theme
```

This is the key programmability pattern on stock firmware — render content as a 240x240 image locally, upload it, then display it. Animated GIFs work the same way.

### Upload a weather screen GIF

```
smalltv-upload-file file_path="/tmp/icon.gif" dir="/gif"
smalltv-write path="/set?gif=/gif/icon.gif"
```

Weather GIFs must be exactly 80x80px.

### Display a specific theme

```
smalltv-write path="/set?theme=3"
```

| # | Theme |
|---|-------|
| 1 | Weather Clock Today |
| 2 | Weather Forecast |
| 3 | Photo Album |
| 4 | Time Style 1 |
| 5 | Time Style 2 |
| 6 | Time Style 3 |
| 7 | Simple Weather Clock |

## Safety Rules

### Destructive endpoints — require explicit user confirmation

| Path | Effect |
|------|--------|
| `/wifisave` (empty) | Wipes WiFi credentials — forces AP mode |
| `/set?reset=1` | Factory reset |
| `/set?reboot=1` | Immediate reboot |
| `/set?clear=image` | Deletes ALL uploaded images |
| `/set?clear=gif` | Deletes ALL uploaded GIFs |
| `/delete?file={path}` | Permanent file deletion |

Never pass these paths to `smalltv-write` without the user explicitly requesting the action.

### Firmware flashing

`smalltv-upload-firmware` requires `confirm: true`. Bad firmware can brick the device. Before flashing:
1. Verify model is `SmallTV-Ultra` via `smalltv-get-device-info`
2. Record current firmware version
3. Confirm the user has a stock `.bin` for rollback
4. Obtain explicit user approval

### Not supported by stock firmware

- **No text display endpoint.** No `/set?txt=`, `/set?text=`, `/set?message=`. Do not probe for text endpoints — they do not exist.
- To display custom text: render it as a 240x240 JPEG (e.g. Python+Pillow), upload with `smalltv-upload-file`, then display with `smalltv-write`.
- No video, no audio, no touchscreen, no WebSocket/MQTT push.

## Device IP Handling

All tools accept an optional `device_ip` parameter. Pass it if known to avoid relying on the server's `SMALLTV_IP` environment variable. Load the IP from `.claude/geekmagic-smalltv-ultra.local.md` when available (managed by the geekmagic-smalltv-ultra skill).

## Reference

For detailed device documentation beyond MCP tool usage:
- **Complete HTTP API, settings, JSON endpoints**: see the **geekmagic-smalltv-ultra** skill and its `references/device-reference.md`
- **Alternative firmware (bvweerd, ESPHome, Tasmota)**: see `references/alternative-firmware-guide.md`
- **Custom firmware development**: see `references/custom-firmware-guide.md`
- **MCP server resources** (attachable to context): `smalltv-api-reference`, `smalltv-safety-guide`
