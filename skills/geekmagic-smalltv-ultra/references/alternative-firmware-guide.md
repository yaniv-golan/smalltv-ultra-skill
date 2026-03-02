# Alternative Firmware Guide — GeekMagic SmallTV Ultra

## Overview

The SmallTV Ultra ships with closed-source stock firmware. Three alternative firmware options exist, each with different trade-offs. This guide covers detailed comparison, installation procedures, risk assessment, and rollback instructions.

## Pre-Flash Checklist (All Firmware Options)

Complete every item before flashing any firmware:

1. **Verify model**: `curl -s http://{IP}/v.json` — response MUST contain `"m":"SmallTV-Ultra"`. The Pro model uses ESP32 and is incompatible.
2. **Record current version**: Note the `"v"` field (e.g., `Ultra-V9.0.43`) for rollback reference.
3. **Download stock firmware**: Get the matching `.bin` from https://github.com/GeekMagicClock/smalltv-ultra — this is the rollback file.
4. **Verify stock .bin integrity**: Check MD5 hash matches the one listed in the repo. Antivirus software may modify `.bin` files.
5. **Confirm OTA access**: Navigate to `http://{IP}/update` in a browser — the upload form must load.
6. **Backup uploaded files**: Download any images/GIFs from `/filelist?dir=/image/` and `/filelist?dir=/gif` that should be preserved.
7. **Obtain explicit user confirmation** before proceeding.

---

## Detailed Comparison

| Feature | Stock Firmware | bvweerd | ESPHome | Tasmota |
|---------|---------------|---------|---------|---------|
| **Install method** | Pre-installed | OTA web upload | UART (soldering required) | UART (soldering required) |
| **Difficulty** | N/A | Easy | Hard | Hard |
| **Reversible via OTA?** | N/A | Yes | Only if OTA was configured | Only if OTA was configured |
| **Hardware tools needed** | None | None | USB-UART adapter + soldering | USB-UART adapter + soldering |
| **Source code** | Closed | Open (Arduino/PlatformIO) | YAML config (open) | YAML config (open) |
| **Custom text display** | No (images only) | Yes (`/api/update` endpoint) | Yes (HA entities) | Limited |
| **Weather/clock themes** | 7 built-in themes | Most preserved (API-compatible) | None (replaced entirely) | None (replaced entirely) |
| **GeekMagic API compat** | Full | Full + extensions | None | None |
| **Home Assistant** | Via HACS image push | Via HACS + native text API | Native ESPHome integration | Native Tasmota integration |
| **mDNS** | No | Yes (`smartclock.local`) | Yes | Yes |
| **MQTT** | No | No | Yes | Yes |
| **OTA updates** | Via `/update` page | Via `/update` + ArduinoOTA | Via ESPHome dashboard | Via Tasmota web UI |
| **Filesystem** | SPIFFS | LittleFS | LittleFS | LittleFS |
| **Debug logging** | None | `/log` endpoint | ESPHome logs | Tasmota console |
| **Crash recovery** | Manual (power cycle 3x) | Auto-reset after 5 failures | Watchdog | Watchdog |
| **Community support** | GeekMagic GitHub | bvweerd repo issues | HA community forums | Tasmota discussions |
| **Maturity** | Production (manufacturer) | Active development | Community configs | Early discussion |

---

## Option 1: bvweerd Open-Source Firmware (Recommended First Alternative)

### Why Choose This

- **Easiest to install**: OTA upload, no soldering, no special hardware
- **Easiest to revert**: Flash stock `.bin` back via the same OTA page
- **Lowest risk**: If something goes wrong, OTA recovery is straightforward
- **Adds features without losing stock ones**: GeekMagic API compatibility preserved
- **Custom text API**: The `/api/update` endpoint enables live text display — the single most-requested feature stock firmware lacks
- **Open source**: Full Arduino/PlatformIO codebase to modify and extend

### What It Adds Over Stock

- `POST /api/update` — Display custom text and progress bar:
  ```json
  {"line1": "Server Status", "line2": "All OK", "bar": 0.95}
  ```
- mDNS discovery at `smartclock.local` (no need to know IP)
- ArduinoOTA for wireless firmware updates from PlatformIO
- `/log` endpoint for real-time debug output
- `/factoryreset` and `/reconfigurewifi` dedicated endpoints
- Boot failure detection — auto-resets after 5 consecutive boot failures
- Random AP password per boot (security improvement over stock's open AP)
- LittleFS instead of SPIFFS (more reliable, better wear leveling)

### What It Loses

- Exact visual parity with stock themes (layout/rendering may differ slightly)
- Stock firmware's specific weather rendering
- GeekMagic's proprietary optimizations (if any)

### Installation Procedure

1. Complete the Pre-Flash Checklist above.
2. Clone the repository:
   ```bash
   git clone https://github.com/bvweerd/geekmagic-tv-esp8266.git
   cd geekmagic-tv-esp8266
   ```
3. Install PlatformIO (if not already installed):
   ```bash
   pip install platformio
   # or: brew install platformio (macOS)
   ```
4. Build the firmware:
   ```bash
   pio run
   ```
   The `.bin` output will be in `.pio/build/esp12e/firmware.bin`.
5. Open the device's OTA page: `http://{IP}/update`
6. Upload the `.bin` file.
7. Wait for the device to reboot (30-60 seconds).
8. Verify: The device should create a WiFi AP with a random password displayed on screen.
9. Connect to the AP, configure WiFi at `http://192.168.4.1`.
10. Once connected, verify via `http://smartclock.local/` or the device's new IP.

### Rollback to Stock

1. Navigate to `http://{IP}/update` (or `http://smartclock.local/update`).
2. Upload the stock `.bin` file downloaded during pre-flash checklist.
3. Wait for reboot. Device returns to stock firmware.
4. May need to reconfigure WiFi (power cycle 3x if needed to enter AP mode).

---

## Option 2: ESPHome

### Why Choose This

- **Deep Home Assistant integration**: Native ESPHome entities, automations, dashboards
- **YAML-based configuration**: No C/C++ coding required
- **Real-time updates**: Entity values update automatically
- **MQTT support**: For non-HA automation systems
- **Large community**: Extensive ESPHome documentation and examples

### What It Loses

- **ALL stock features**: Weather themes, clock faces, photo album — completely replaced
- **GeekMagic API**: No HTTP API compatibility
- **Easy OTA from stock**: Initial flash requires UART (soldering)
- **Standalone operation**: Requires Home Assistant or similar backend

### Risks

- **Medium risk**: Requires soldering to UART pins on PCB
- **Reversibility depends on setup**: If OTA is configured in ESPHome YAML, can reflash wirelessly. If not, UART is needed again.
- **Physical damage possible**: Incorrect soldering can damage the PCB
- **No manufacturer support**: Voids any implied warranty

### Hardware Requirements

- USB-to-UART adapter (e.g., CP2102, CH340, FTDI)
- Soldering iron + fine-tip solder
- Dupont/jumper wires
- Access to GPIO pin holes on PCB (may require partial disassembly)

### UART Pin Connections

| ESP8266 Pin | UART Adapter Pin |
|-------------|-----------------|
| TX | RX |
| RX | TX |
| GND | GND |
| GPIO0 | GND (for flash mode) |
| 3.3V | 3.3V (NOT 5V!) |

**CRITICAL**: Use 3.3V power from the UART adapter, NOT 5V. The ESP8266 is a 3.3V chip. 5V will damage it permanently.

### ESPHome YAML Configuration

Reference config from community (adapt as needed):
```yaml
esphome:
  name: smalltv-ultra
  platform: ESP8266
  board: esp12e

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

spi:
  clk_pin: GPIO14
  mosi_pin: GPIO13

display:
  - platform: st7789v
    cs_pin: GPIO15
    dc_pin: GPIO0
    reset_pin: GPIO2
    backlight_pin: GPIO5
    rotation: 0
    dimensions:
      height: 240
      width: 240
    lambda: |-
      it.print(120, 120, id(font1), TextAlign::CENTER, "Hello!");

font:
  - file: "gfonts://Roboto"
    id: font1
    size: 24
```

### Installation Procedure

1. Complete the Pre-Flash Checklist above.
2. Disassemble the device to access the PCB UART pin holes.
3. Solder header pins or wires to TX, RX, GND, GPIO0, and 3.3V pads.
4. Connect USB-UART adapter (TX→RX, RX→TX, GND→GND, 3.3V→3.3V).
5. Hold GPIO0 to GND, then power on (or press reset) to enter flash mode.
6. Flash using ESPHome:
   ```bash
   esphome run smalltv-ultra.yaml
   ```
7. Release GPIO0 from GND.
8. Power cycle the device.
9. Verify in Home Assistant ESPHome dashboard.

### Community Resources

- **ESPHome config gist**: https://gist.github.com/kmplngj/c02d0f3e0d68ad97dc4c2fcd3a0edb51
- **HA community thread**: https://community.home-assistant.io/t/installing-esphome-on-geekmagic-smart-weather-clock-smalltv-pro/618029

---

## Option 3: Tasmota

### Why Choose This

- **Mature firmware**: Tasmota is battle-tested on thousands of ESP8266 devices
- **Web-based configuration**: No coding required after initial flash
- **MQTT native**: First-class MQTT support for automation
- **Rules engine**: Built-in automation without external systems

### Current Status

Tasmota support for the SmallTV Ultra is in **early community discussion** stage. There is no official or well-tested configuration. The ST7789 display driver is supported in Tasmota, but the specific SmallTV Ultra pin mapping and screen initialization may require experimentation.

### Risks

- **Medium-high risk**: Less community validation than ESPHome for this specific device
- **Requires UART**: Same soldering requirements as ESPHome
- **Experimental**: No proven config for this exact hardware
- **Display support uncertain**: ST7789 is supported, but 240x240 square displays may need custom settings

### Community Resources

- **Tasmota discussion**: https://github.com/arendst/Tasmota/discussions/21791

---

## Risk Summary Matrix

| Risk | bvweerd | ESPHome | Tasmota |
|------|---------|---------|---------|
| Bricking device | Very Low (OTA, easy rollback) | Low (UART recovery possible) | Low (UART recovery possible) |
| Physical damage | None (no soldering) | Possible (soldering required) | Possible (soldering required) |
| Loss of stock features | Minimal | Complete | Complete |
| Difficult rollback | No (OTA back to stock) | Moderate (may need UART) | Moderate (may need UART) |
| Community support | Active repo | Large ESPHome community | Large Tasmota community |
| Warranty void | Likely | Certainly | Certainly |
| Data loss | Upload files may need re-upload | All device data replaced | All device data replaced |

## Recommendation Flow

1. **Want to keep stock features + add text display?** → bvweerd
2. **Want deep Home Assistant integration and comfortable soldering?** → ESPHome
3. **Want MQTT-first automation and comfortable soldering?** → Tasmota (experimental)
4. **Want zero risk?** → Stay on stock firmware, use upload-and-display pattern
