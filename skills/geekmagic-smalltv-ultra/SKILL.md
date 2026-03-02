---
name: geekmagic-smalltv-ultra
version: 1.0.0
description: This skill should be used when the user asks to "control the SmallTV", "change SmallTV theme", "upload image to SmallTV", "set SmallTV brightness", "configure SmallTV weather", "install alternative firmware", "flash ESPHome on SmallTV", "install bvweerd firmware", "write custom firmware for ESP8266 display", "build firmware for SmallTV", "update SmallTV firmware", "push image to display", "send text to SmallTV", "connect SmallTV to Home Assistant", "SmallTV WiFi recovery", or mentions the GeekMagic SmallTV Ultra, SmallTV-Ultra, TinyTV, HACS SmallTV integration, or an ESP8266-based 240x240 TFT display device. Covers stock firmware HTTP API usage, alternative firmware installation (bvweerd, ESPHome, Tasmota), and custom ESP8266 firmware development.
---

# GeekMagic SmallTV Ultra

Control, customize, and develop firmware for the GeekMagic SmallTV Ultra — an ESP8266-based IoT device with a 240x240 TFT display, controlled entirely over HTTP with no authentication.

## Device Configuration

Check for saved device settings at `.claude/geekmagic-smalltv-ultra.local.md` before any device interaction.

**If the file exists:** Read the YAML frontmatter to get `device_ip`, `model`, and `firmware_version`. Use the stored IP for all commands. Still verify reachability with `curl -s http://{IP}/v.json` on first use in the session — if it fails, inform the user the device may be offline or the IP may have changed.

**If the file does not exist:** Ask the user for the device IP. To find it: the IP is displayed on the device screen during boot (unplug and replug the USB-C cable — there is no battery), and also briefly shown on the default Weather Clock theme between weather data rotations. After successful verification via `/v.json`, create the settings file:

```markdown
---
device_ip: 192.168.5.253
model: SmallTV-Ultra
firmware_version: Ultra-V9.0.43
last_verified: 2026-03-02
---
```

Populate `model` and `firmware_version` from the `/v.json` response (`m` and `v` fields). Update `last_verified` to the current date. This file persists across sessions so the user only provides the IP once.

**If the device IP changes:** Update the file with the new IP after successful verification. If the firmware version in `/v.json` differs from the stored value, update `firmware_version` in the file and inform the user (e.g., "Device firmware updated from V9.0.43 to V9.0.45 since last session").

## Critical Safety Rules

**No authentication exists on any endpoint.** Every HTTP request executes immediately with no confirmation. Before any write operation:

1. Load the device IP from `.claude/geekmagic-smalltv-ultra.local.md` (or ask the user if not configured)
2. Verify reachability: `curl -s http://{IP}/v.json`
3. Confirm the response contains `"m":"SmallTV-Ultra"` — wrong model means wrong firmware means potential brick
4. Never probe write endpoints without explicit user intent

### Destructive Endpoints — Never Call Without User Confirmation

| Endpoint | Effect |
|----------|--------|
| `/wifisave` with no/empty params | Wipes WiFi credentials, forces AP mode — effectively a factory reset |
| `/set?reset=1` | Factory reset (clears all settings, keeps uploaded files) |
| `/set?reboot=1` | Immediate reboot |
| `/set?clear=image` | Deletes ALL uploaded images |
| `/set?clear=gif` | Deletes ALL uploaded GIFs |
| `/delete?file={path}` | Deletes a specific file permanently |

## Device Overview

- **MCU**: ESP8266 (ESP12F clone), 80MHz, ~80KB RAM, 4MB flash
- **Display**: 1.5" 240x240 IPS TFT, ST7789 driver over SPI
- **Storage**: ~3MB SPIFFS filesystem (~1.2MB free)
- **Connectivity**: 2.4GHz WiFi only, HTTP server on port 80
- **Control**: Full HTTP API via `GET /set?param=value` — returns `"OK"` on success
- **Firmware update**: OTA via `/update` page (upload .bin file)
- **SPI pins**: CLK=GPIO14, MOSI=GPIO13, DC=GPIO0, RST=GPIO2, CS=GPIO15, Backlight=GPIO5

## Workflow Routing

Determine the user's goal and follow the corresponding path.

### Path A: Control Device with Stock Firmware

For API interaction, settings changes, image/GIF uploads, and automation.

**Core pattern**: `curl "http://{IP}/set?{param}={value}"` — returns `"OK"` on success.

| Task | Command |
|------|---------|
| Check device | `GET /v.json` → `{"m":"SmallTV-Ultra","v":"Ultra-V9.0.XX"}` |
| Set theme (1-7) | `GET /set?theme={1-7}` |
| Set brightness | `GET /set?brt={-10 to 100}` |
| Set city | `GET /set?cd1={city_name}&cd2=1000` |
| Check storage | `GET /space.json` → `{"total":3121152,"free":NNNNNN}` |
| Upload image/GIF to album | `POST /doUpload?dir=/image/` (multipart form-data, field name: `file`) |
| Upload GIF to weather screen | `POST /doUpload?dir=/gif` (must be 80x80px) |
| Display specific image/GIF | `GET /set?img=/image/{filename}` then `GET /set?theme=3` |
| Set weather screen GIF | `GET /set?gif=/gif/{filename}` |
| List album files | `GET /filelist?dir=/image/` |
| List weather GIFs | `GET /filelist?dir=/gif` |

**Upload-and-display pattern** — the key programmability mechanism on stock firmware:

```bash
# 1. Generate/prepare a 240x240 JPEG or GIF
# 2. Upload it
curl -F "file=@dashboard.jpg" "http://{IP}/doUpload?dir=/image/"
# 3. Set it as the active image
curl "http://{IP}/set?img=/image/dashboard.jpg"
# 4. Switch to Photo Album theme
curl "http://{IP}/set?theme=3"
```

Both JPEG and GIF files work in the album. Animated GIFs play automatically. The same upload endpoint and theme=3 display pattern apply to both formats.

This is how the Home Assistant HACS integration works — render server-side, push via API, repeat on interval.

**GIF constraints**: Album GIFs should be 240x240px. Weather screen GIFs must be exactly 80x80px (uploaded to `/gif` instead of `/image/`). Keep GIFs small — the device has ~1.2MB free storage and limited RAM for decoding. Fewer frames and smaller dimensions reduce playback lag.

For the complete API (weather config, time colors, night mode, auto-theme switching, countdown timer, WiFi config, file management), consult **`references/device-reference.md`**.

### Path B: Display Custom Content

**On stock firmware (no flashing required):** Render content as 240x240 images programmatically and use the upload-and-display pattern from Path A above. Stock firmware has no API for arbitrary text — everything must be an image or GIF.

**Generating static images (JPEG):** Use Python/Pillow, ImageMagick, HTML-to-image, or any tool that outputs 240x240 JPEG. Example with Pillow:

```python
from PIL import Image, ImageDraw, ImageFont
import requests

img = Image.new("RGB", (240, 240), "black")
draw = ImageDraw.Draw(img)
draw.text((10, 100), "Hello SmallTV!", fill="white")
img.save("dashboard.jpg", quality=85)

# Upload and display
with open("dashboard.jpg", "rb") as f:
    requests.post("http://{IP}/doUpload?dir=/image/", files={"file": f})
requests.get("http://{IP}/set?img=/image/dashboard.jpg")
requests.get("http://{IP}/set?theme=3")
```

**Generating animated GIFs:** Use Pillow to create multi-frame GIFs for the album (240x240) or weather overlay (80x80):

```python
from PIL import Image, ImageDraw
frames = []
for i in range(10):
    img = Image.new("RGB", (240, 240), "black")
    draw = ImageDraw.Draw(img)
    draw.text((10 + i * 5, 100), "Frame", fill="white")
    frames.append(img)
frames[0].save("anim.gif", save_all=True, append_images=frames[1:],
               duration=200, loop=0)
```

Keep GIFs small (few frames, limited palette) — the device has constrained RAM and storage.

**Common recipe — system stats dashboard:**

```python
import psutil
from PIL import Image, ImageDraw
img = Image.new("RGB", (240, 240), "#1a1a2e")
draw = ImageDraw.Draw(img)
draw.text((10, 20), f"CPU: {psutil.cpu_percent()}%", fill="#00ff88")
draw.text((10, 60), f"RAM: {psutil.virtual_memory().percent}%", fill="#00ff88")
draw.text((10, 100), f"Disk: {psutil.disk_usage('/').percent}%", fill="#00ff88")
img.save("stats.jpg", quality=85)
# Then upload and display via the pattern above
```

Run on a cron or loop to push live stats to the display.

**For live text display (no image rendering):** Install bvweerd's open-source firmware, which adds:
```
POST /api/update
Content-Type: application/json
{"line1": "Hello", "line2": "World", "bar": 0.7}
```
This firmware is OTA-installable and OTA-reversible. See Path C.

### Path C: Install Alternative Firmware

**Always complete these validation gates before flashing:**

1. Verify model: `curl -s http://{IP}/v.json` — must show `SmallTV-Ultra`, NOT `SmallTV-Pro`
2. Record current firmware version for reference
3. Download matching stock `.bin` from https://github.com/GeekMagicClock/smalltv-ultra for rollback
4. Confirm `/update` page is accessible at `http://{IP}/update`
5. Obtain explicit user confirmation before proceeding

**Quick comparison:**

| | bvweerd | ESPHome | Tasmota |
|---|---------|---------|---------|
| Install method | OTA (easy) | UART soldering (hard) | UART soldering (hard) |
| Reversible via OTA? | Yes | Only if OTA configured | Only if OTA configured |
| Custom text API | Yes | Yes (HA entities) | Limited |
| Stock features kept | Most | None | None |
| Risk level | Low | Medium | Medium |
| Source | Open (Arduino) | YAML config | YAML config |

For detailed installation procedures, rollback steps, and risk assessment, consult **`references/alternative-firmware-guide.md`**.

### Path D: Write Custom Firmware

For building entirely new firmware from scratch on the ESP8266 + ST7789 platform.

**Prerequisites**: PlatformIO, C/C++ for Arduino framework, understanding of ESP8266 constraints.

**Quick start:**
1. Clone https://github.com/bvweerd/geekmagic-tv-esp8266 as a working starting point
2. Set up PlatformIO with `esp8266` platform and `TFT_eSPI` library
3. Configure SPI pins: CLK=14, MOSI=13, DC=0, RST=2, CS=15, BL=5
4. Build: `pio run`
5. Flash via OTA: upload `.bin` to `http://{IP}/update`
6. Revert: flash stock `.bin` the same way

**Critical ESP8266 constraints:**
- ~80KB heap — aggressive memory management required
- Single-threaded — display rendering blocks HTTP serving
- No HTTPS/TLS
- SPIFFS ~3MB total — budget file storage carefully
- 240x240 RGB565 16-bit color

For the full development guide (PlatformIO config, TFT_eSPI setup, code patterns, web server implementation, memory management, debugging), consult **`references/custom-firmware-guide.md`**.

## Safe Read-Only Endpoints

These JSON endpoints are safe for status checks and never modify device state:

| Endpoint | Returns |
|----------|---------|
| `/v.json` | Model and firmware version |
| `/city.json` | City configuration |
| `/space.json` | Storage total and free bytes |
| `/album.json` | Album autoplay settings |
| `/wifi.json?q=1` | WiFi scan results |
| `/config.json` | WiFi SSID and password (sensitive!) |

## WiFi Recovery

If the device loses WiFi (wrong credentials, network change):
1. Power cycle 3 times rapidly (plug in, unplug when progress bar shows, repeat 3x)
2. Device enters AP mode — creates "GIFTV" hotspot
3. Connect to "GIFTV", navigate to http://192.168.4.1
4. Configure correct WiFi credentials

## Reference Files

- **`references/device-reference.md`** — Complete HTTP API reference, all settings endpoints, JSON data formats, file management, theme details, web console pages, HACS integration, community resources
- **`references/alternative-firmware-guide.md`** — Detailed firmware comparison, step-by-step installation for bvweerd/ESPHome/Tasmota, risk assessment, rollback procedures, feature trade-offs
- **`references/custom-firmware-guide.md`** — PlatformIO project setup, TFT_eSPI pin configuration, ESP8266 development patterns, web server implementation, memory management, OTA updates, build and flash workflow
