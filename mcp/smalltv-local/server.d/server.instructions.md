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

## NOT SUPPORTED by the stock firmware

- **No text display endpoint.** There is no `/set?txt=`, `/set?text=`,
  `/set?notify=`, `/set?message=`, or `/set?scrolltext=`. Do not guess
  or probe for text endpoints — they do not exist.
- **To display custom text**: render it as a 240x240 JPEG image (e.g.
  using Python+Pillow or ImageMagick), upload with `smalltv-upload-file`
  to `/image/`, then display with `smalltv-write /set?img=/image/{file}`
  and `smalltv-write /set?theme=3`.
- No video playback, no audio, no touchscreen input.
- No WebSocket or MQTT push — poll JSON endpoints for status.
- No HTTPS/TLS — all traffic is unencrypted HTTP.
- 2.4GHz WiFi only (ESP8266).

## Safety Defaults

- Prefer read-only endpoints before any write operation.
- **Never call destructive endpoints without explicit user intent:**
  - `/wifisave` (empty call wipes WiFi credentials)
  - `/set?reset=1` (factory reset)
  - `/set?reboot=1` (immediate reboot)
  - `/set?clear=image` or `/set?clear=gif` (deletes all uploads)
  - `/delete?file=...` (permanent file deletion)
- Do not probe unknown `/set?` parameters — unsupported params may
  return `"FAIL"` or status code 0. Only use the parameters listed below.
- **Never flash firmware** without explicit user approval and
  `confirm=true`.

## Complete `/set?` Parameter Reference

These are ALL valid `/set?` parameters. Any parameter not listed here
does not exist in the stock firmware.

| Parameter | Example | Effect |
|-----------|---------|--------|
| `theme` | `/set?theme=3` | Set display theme (1-7) |
| `theme_list` | `/set?theme_list=1,0,1,0,0,0,1&sw_en=1&theme_interval=30` | Auto theme switching |
| `brt` | `/set?brt=50` | Brightness (-10 to 100) |
| `t1,t2,b1,b2,en` | `/set?t1=22&t2=7&b1=50&b2=10&en=1` | Night mode |
| `cd1,cd2` | `/set?cd1=Seoul&cd2=1000` | Set city |
| `w_u,t_u,p_u` | `/set?w_u=km/h&t_u=°C&p_u=hPa` | Weather units |
| `w_i` | `/set?w_i=20` | Weather update interval (minutes) |
| `key` | `/set?key={api_key}` | OpenWeatherMap API key |
| `fkey` | `/set?fkey={key}` | Forecast API key |
| `hour` | `/set?hour=0` | 0=24h, 1=12h |
| `day` | `/set?day=1` | Date format (1-5) |
| `colon` | `/set?colon=1` | Colon blink |
| `font` | `/set?font=1` | 1=Big, 2=Digital |
| `ntp` | `/set?ntp=pool.ntp.org` | NTP server |
| `dst` | `/set?dst=1` | Daylight saving |
| `hc,mc,sc` | `/set?hc=%23FF0000&mc=%23FFFFFF&sc=%2300FF00` | Clock colors (URL-encoded hex) |
| `yr,mth,day` | `/set?yr=2026&mth=12&day=25` | Countdown timer |
| `autoplay` | `/set?autoplay=1` | Album auto-display |
| `i_i` | `/set?i_i=5` | Image interval (seconds) |
| `img` | `/set?img=/image/hello.jpg` | Display specific image |
| `gif` | `/set?gif=/gif/custom.gif` | Weather screen GIF (80x80) |
| `delay` | `/set?delay=5` | WiFi connection delay |
| `reset` | `/set?reset=1` | **DESTRUCTIVE**: factory reset |
| `reboot` | `/set?reboot=1` | **DESTRUCTIVE**: reboot |
| `clear` | `/set?clear=image` | **DESTRUCTIVE**: delete all images or GIFs |

## JSON Read Endpoints

| Endpoint | Returns |
|----------|---------|
| `/v.json` | Model and firmware version |
| `/city.json` | City configuration |
| `/space.json` | Storage total and free bytes |
| `/album.json` | Album autoplay settings |
| `/config.json` | WiFi SSID and password |
| `/wifi.json?q=1` | WiFi scan results |

## File Management

| Operation | Tool | Path |
|-----------|------|------|
| List album files | `smalltv-read` | `/filelist?dir=/image/` |
| List GIF files | `smalltv-read` | `/filelist?dir=/gif` |
| Upload image | `smalltv-upload-file` | (local file path) |
| Delete file | `smalltv-write` | `/delete?file={url-encoded-path}` |
| View/download file | `smalltv-read` | `/{filepath}` |

## Display Themes

| # | Theme |
|---|-------|
| 1 | Weather Clock Today |
| 2 | Weather Forecast |
| 3 | Photo Album (use this to display uploaded images) |
| 4 | Time Style 1 (customizable colors) |
| 5 | Time Style 2 |
| 6 | Time Style 3 |
| 7 | Simple Weather Clock |

## Reference Resources (user-selectable)

This server also exposes MCP resources with expanded documentation.
Users can attach these to their context for additional detail:
- `file://./resources/api-reference.md` — full HTTP API catalog
- `file://./resources/safety-guide.md` — safety rules and device constraints
