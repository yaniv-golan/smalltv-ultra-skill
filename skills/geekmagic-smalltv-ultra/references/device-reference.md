# GeekMagic SmallTV-Ultra - Complete Device Reference

## Hardware Specs
- **Model**: SmallTV-Ultra
- **Firmware**: Ultra-V9.0.43 (latest available: V9.0.45)
- **MCU**: ESP12F clone (CS-12F-N4 module) — ESP8266-based (WiFi 2.4GHz only, no 5GHz)
- **Display driver**: ST7789-compatible TFT via SPI
- **Screen**: 1.5 inch 240x240px TFT IPS display
- **Size**: 35mm x 39mm x 49mm, under 100g
- **Power**: 5V DC, 1A+ via USB-C (Type-C to Type-C NOT supported)
- **Storage**: ~3MB SPIFFS filesystem (total: 3,121,152 bytes)
- **Free space**: ~1.2MB (1,228,300 bytes currently)
- **IP Address**: 192.168.5.253 (DHCP assigned, shown on boot screen)
- **Web Server**: HTTP on port 80, gzip-compressed responses, keep-alive
- **Hardware debug**: ISP connector footprint for direct firmware flashing; UART GPIO pin holes

### SPI Pin Mapping (from community reverse engineering)
| Function | GPIO |
|----------|------|
| CLK | 14 |
| MOSI | 13 |
| DC | 0 |
| RST | 2 |
| CS | 15 |
| Backlight | 5 |

### ESP8266 Constraints
- **CPU**: 80MHz single core (can be clocked to 160MHz)
- **RAM**: ~80KB heap available
- **Flash**: Likely 4MB total (common for ESP12F modules)
- **Partition**: Firmware + SPIFFS (~3MB for filesystem)
- **Networking**: Single-threaded — display rendering blocks HTTP serving briefly
- **Arduino board target**: "Generic ESP8266 Module" or "NodeMCU 1.0" in PlatformIO/Arduino IDE

### Display Configuration
- **Driver**: ST7789
- **SPI Mode**: SPI_MODE3
- **Resolution**: 240x240
- **Color format**: RGB565 (16-bit, standard for ST7789)
- **Rotation**: TBD (may need experimentation; stock firmware handles this)
- **Libraries**: TFT_eSPI (recommended, fast) or Adafruit_GFX + Adafruit_ST7789

### Flashing Custom Firmware
- **OTA (easy, no hardware needed)**: Stock firmware's `/update` page accepts `.bin` uploads.
  Build the firmware, upload via `http://192.168.5.253/update`. Can flash back to stock
  the same way using the `.bin` files from the GitHub repo.
- **UART (recovery)**: GPIO pin holes on PCB for serial flashing if OTA bricks the device.
- **Reference codebase**: Clone https://github.com/bvweerd/geekmagic-tv-esp8266 as a
  working starting point — it's a complete ESP8266 + ST7789 project with the same
  pin mapping, web server, file upload, and GeekMagic API compatibility already implemented.

## WiFi Modes
- **AP Mode** (setup): Creates hotspot "GIFTV", access at http://192.168.4.1
- **STA Mode** (normal): Connects to configured WiFi, web console at device IP
- **Reset**: Power cycle 3 times rapidly (plug in, unplug when progress bar shows, repeat 3x)
- **Delay**: Configurable WiFi connection delay after boot (for slow routers)

---

## Web Console Pages

| Page | URL | Purpose |
|------|-----|---------|
| Settings (home) | `/` or `/settings.html` | Theme selection, brightness, night mode, reset, reboot, firmware |
| Network | `/network.html` | WiFi scan, connect, delay config |
| Weather | `/weather.html` | City, units, API keys, weather GIF, forecast key |
| Time | `/time.html` | Clock colors, 12/24h, date format, colon blink, font, NTP, DST |
| Pictures | `/image.html` | Photo album management, auto-display, upload JPG/GIF |
| Firmware Update | `/update` | Upload .bin or .bin.gz firmware files |

---

## Complete HTTP API Reference

All settings are applied via GET requests to `/set` with query parameters.
Response: `"OK"` on success, error string on failure.

### Theme Control
```
GET /set?theme={1-7}
```
| Value | Theme |
|-------|-------|
| 1 | Weather Clock Today |
| 2 | Weather Forecast |
| 3 | Photo Album |
| 4 | Time Style 1 |
| 5 | Time Style 2 |
| 6 | Time Style 3 |
| 7 | Simple Weather Clock |

### Auto Theme Switching
```
GET /set?theme_list={csv}&sw_en={0|1}&theme_interval={seconds}
```
- `theme_list`: comma-separated 0/1 for each theme (e.g., `1,0,1,0,0,0,1`)
- `sw_en`: enable (1) or disable (0) auto-switching
- `theme_interval`: seconds between theme changes

### Brightness
```
GET /set?brt={-10 to 100}
```

### Night Mode
```
GET /set?t1={start_hour}&t2={end_hour}&b1=50&b2={night_brightness}&en={0|1}
```
- `t1`: Start hour (0-23), e.g., 22 for 10PM
- `t2`: End hour (0-23), e.g., 7 for 7AM
- `b2`: Brightness during night (-10 to 100)
- `en`: Enable (1) or disable (0)

### Weather / City
```
GET /set?cd1={city_name_or_code}&cd2=1000
```
- `cd1`: City name (e.g., "Seoul") or OpenWeatherMap city ID (e.g., "1835848")
- `cd2`: Always "1000" (likely a legacy parameter)

### Weather Units
```
GET /set?w_u={wind}&t_u={temp}&p_u={pressure}
```
- Wind: `m/s`, `km/h`, `mile/h`
- Temperature: `°C`, `°F`
- Pressure: `hPa`, `kPa`, `mmHg`, `inHg`

### Weather Update Interval
```
GET /set?w_i={minutes}
```
Default: 20 minutes. Custom API key allows higher frequency.

### Weather API Keys
```
GET /set?key={openweathermap_api_key}
GET /set?fkey={forecast_api_key}
```

### Time Settings
```
GET /set?hour={0|1}          # 0=24h, 1=12h format
GET /set?day={1-5}           # Date format (1=DD/MM/YYYY, 2=YYYY/MM/DD, 3=MM/DD/YYYY, 4=MM/DD, 5=DD/MM)
GET /set?colon={0|1}         # Colon blink enable
GET /set?font={1|2}          # 1=Default Big Font, 2=Digital Font
GET /set?ntp={server}        # NTP server domain (e.g., pool.ntp.org)
GET /set?dst={0|1}           # Daylight saving time enable
```

### Time Number Colors
```
GET /set?hc={color}&mc={color}&sc={color}
```
- `hc`: Hour color (URL-encoded hex, e.g., `%23FFFFFF`)
- `mc`: Minutes color
- `sc`: Seconds color

### Countdown Timer
```
GET /set?yr={year}&mth={month}&day={day}
```

### Photo Album Settings
```
GET /set?autoplay={0|1}      # Enable auto-display
GET /set?i_i={seconds}       # JPG display interval
GET /set?img={filepath}      # Set specific image to display (URL-encoded path)
```

### GIF on Weather Screen
```
GET /set?gif={filepath}      # Set GIF for weather screen (80x80px, URL-encoded)
```

### WiFi Configuration
```
GET /wifisave?s={ssid}&p={password}
```
Both values should be URL-encoded. Device reboots after saving.

> **WARNING**: `/wifisave` is a destructive endpoint. Hitting it with no parameters
> (or empty `s=`/`p=`) saves blank WiFi credentials, causing the device to
> lose its WiFi connection and fall back to AP mode ("GIFTV" hotspot), effectively
> a factory-reset-like state. This was observed during testing — a bare
> `GET /wifisave` (no query params) triggered a full settings wipe and reboot into
> AP mode. Always provide valid SSID and password when calling this endpoint.

### WiFi Connection Delay
```
GET /set?delay={seconds}
```

### System Commands
```
GET /set?reset=1             # Factory reset (clears settings, keeps uploaded files)
GET /set?reboot=1            # Reboot device
GET /set?clear=image         # Delete all files in /image/
GET /set?clear=gif           # Delete all files in /gif/
```

> **WARNING - Destructive Endpoints**: Several endpoints have side effects even
> when called with no or empty parameters. Known dangerous endpoints:
> - `/wifisave` - Saves WiFi creds; empty call wipes them (see above)
> - `/set?reset=1` - Factory reset
> - `/set?reboot=1` - Immediate reboot
> - `/set?clear=image` / `/set?clear=gif` - Deletes all uploaded files
> - `/delete?file=...` - Deletes a specific file
>
> There is **no authentication** on any endpoint. Do not probe write endpoints
> with blind GET requests.

---

## JSON Data Endpoints (GET)

| Endpoint | Returns | Example |
|----------|---------|---------|
| `/v.json` | Model & firmware version | `{"m":"SmallTV-Ultra","v":"Ultra-V9.0.43"}` |
| `/city.json` | City config | `{"ct":"Kfar Saba","t":"2","mt":"0","cd":"Kfar Saba","loc":"Kfar Saba,IL"}` |
| `/config.json` | WiFi SSID & password | `{"a":"Golan","p":"****"}` |
| `/space.json` | Storage info | `{"total":3121152,"free":1228300}` |
| `/album.json` | Album settings | `{"autoplay":1,"i_i":5}` |
| `/wifi.json?q=1` | WiFi scan results | `{"aps":[{"c":"1","ss":"SSID","e":1,"r":55},...]}` |

**Note**: Many JSON endpoints (`/brt.json`, `/delay.json`, `/app.json`, `/timebrt.json`, `/theme_list.json`, `/w_i.json`, `/unit.json`, `/key.json`, `/dst.json`, `/hour12.json`, `/ntp.json`, `/day.json`, `/timecolor.json`, `/font.json`, `/colon.json`, `/daytimer.json`) returned 404 during testing. These may be dynamically generated only when the corresponding page is loaded, or may require specific firmware versions.

WiFi scan JSON format: `c`=channel, `ss`=SSID, `e`=encryption, `r`=signal strength (%)

---

## File Management API

### List Files
```
GET /filelist?dir={path}
```
- `/filelist?dir=/image/` - List photo album files
- `/filelist?dir=/gif` - List weather GIF files
- Returns HTML table with file entries

### Upload Files
```
POST /doUpload?dir={path}
Content-Type: multipart/form-data
```
- Upload to `/image/` for album photos (JPG/GIF, max 240x240px)
- Upload to `/gif` for weather screen GIFs (80x80px)
- JPG files are auto-cropped to 240x240 by the web UI's JavaScript cropper
- GIF files must be pre-resized before upload

### Delete File
```
GET /delete?file={filepath}
```
URL-encoded filepath, e.g., `/delete?file=%2Fimage%2F%2Fspaceman.gif`

### Download/View File
```
GET {filepath}
```
Files are directly accessible, e.g., `GET /image//ezgif-1-795e37b516.jpg`

---

## Display Themes Detail

1. **Weather Clock Today** - Current weather + clock
2. **Weather Forecast** - Multi-day weather forecast
3. **Photo Album** - Slideshow of uploaded JPG/GIF images
4. **Time Style 1** - Clock display style 1 (customizable colors)
5. **Time Style 2** - Clock display style 2
6. **Time Style 3** - Clock display style 3
7. **Simple Weather Clock** - Minimalist weather + time

---

## Capabilities Summary

**What it CAN do:**
- Display time in various styles with customizable colors
- Show current weather and forecasts (via OpenWeatherMap)
- Display uploaded images (JPG) and animated GIFs
- Auto-rotate through themes on a timer
- Night mode with scheduled dimming
- Custom NTP server
- DST support
- Custom weather GIF overlay (80x80px)
- OTA firmware updates via web or .bin upload
- Full programmatic control via HTTP API (no authentication!)
- Serve as a programmable display via upload-and-display pattern (see HACS integration)

**What it CANNOT do:**
- 5GHz WiFi (ESP8266 = 2.4GHz only)
- HTTPS/TLS (all HTTP, no encryption)
- Authentication (no login, anyone on network can control it)
- Custom text display (no stock API for arbitrary text — only via image rendering)
- Real-time data push (no WebSocket, no MQTT)
- Large files (SPIFFS ~3MB total, ~1.2MB free)
- Video playback
- Sound/audio
- Touch input (no touchscreen)
- Custom clock faces beyond the 7 built-in themes

---

## Home Assistant Integration (HACS)

**Repo**: https://github.com/adrienbrault/geekmagic-hacs

A server-side rendering integration that works with **stock firmware** (no flashing needed).
It renders dashboard images in HA using Python/Pillow, then pushes them to the device
via the `/doUpload` + `/set?img=` API. The workflow:

1. Render a 240x240 JPEG dashboard image on the HA server
2. `POST /doUpload?dir=/image/` with the JPEG as multipart form data (field: "file")
3. `GET /set?img=/image/dashboard.jpg` to display it
4. `GET /set?theme=3` to ensure Photo Album theme is active
5. Repeat on a configurable interval (5-300 seconds)

**Capabilities via HACS**: 14 widget types (clock, entity, gauge, chart, weather, camera, etc.),
19 layout options, 10 visual themes. Supports notifications with temporary alert display.

**Additional Pro-only endpoints** found in the HACS code:
```
GET /set?page=1          # Navigate next (Pro touch button)
GET /set?page=-1         # Navigate previous
GET /set?enter=-1        # Press enter/menu
GET /.sys/app.json       # Pro model detection
```

---

## Key Community Resources

- **Official GitHub**: https://github.com/GeekMagicClock/smalltv-ultra
- **GeekMagic GitHub Org**: https://github.com/GeekMagicClock
- **HACS Integration**: https://github.com/adrienbrault/geekmagic-hacs
- **Open Source FW**: https://github.com/bvweerd/geekmagic-tv-esp8266
- **ESPHome Config**: https://gist.github.com/kmplngj/c02d0f3e0d68ad97dc4c2fcd3a0edb51
- **Hardware Teardown**: https://puddleofcode.com/story/my-own-geekmagic-smalltv/
- **Elektor Review**: https://www.elektormagazine.com/review/geekmagic-smarttv-ultra
- **GIF Resources**: https://github.com/GeekMagicClock/gif
- **Support Email**: GeekMagic@163.com / ifengchao1314@gmail.com
