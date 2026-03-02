# Custom Firmware Development Guide — GeekMagic SmallTV Ultra

## Overview

This guide covers building entirely custom firmware for the SmallTV Ultra from scratch, using PlatformIO with the Arduino framework for ESP8266. The bvweerd open-source firmware is the recommended starting point — it provides a working, tested codebase with the correct pin mappings, display initialization, web server, and GeekMagic API compatibility already implemented.

## Prerequisites

- **PlatformIO** (CLI or IDE): https://platformio.org/install
- **Git**: For cloning reference code
- **C/C++ knowledge**: Arduino framework, basic embedded programming
- **Understanding of ESP8266 constraints**: See "ESP8266 Constraints" section below
- **The device itself**: SmallTV Ultra with OTA `/update` page accessible

## Recommended Starting Point

Clone the bvweerd reference implementation rather than starting from zero:

```bash
git clone https://github.com/bvweerd/geekmagic-tv-esp8266.git
cd geekmagic-tv-esp8266
```

This provides:
- Correct SPI pin configuration for the ST7789 display
- Working web server with file upload
- GeekMagic API compatibility (`/set?theme=`, `/set?brt=`, etc.)
- WiFi manager (AP mode + STA mode)
- LittleFS filesystem integration
- OTA update support
- The `/api/update` custom text endpoint

Modify this codebase rather than reinventing the foundational components.

## Starting From Scratch

If building from zero is required (or preferred), follow this section.

### PlatformIO Project Setup

Create a new PlatformIO project:

```bash
mkdir my-smalltv-firmware
cd my-smalltv-firmware
pio init --board esp12e --project-option "framework=arduino"
```

### platformio.ini Configuration

```ini
[env:esp12e]
platform = espressif8266
board = esp12e
framework = arduino
board_build.filesystem = littlefs
board_build.ldscript = eagle.flash.4m1m.ld
monitor_speed = 115200
upload_speed = 921600

; Libraries
lib_deps =
    TFT_eSPI
    ArduinoJson

; TFT_eSPI build flags for SmallTV Ultra pin mapping
build_flags =
    -DUSER_SETUP_LOADED=1
    -DST7789_DRIVER=1
    -DTFT_WIDTH=240
    -DTFT_HEIGHT=240
    -DTFT_MOSI=13
    -DTFT_SCLK=14
    -DTFT_CS=15
    -DTFT_DC=0
    -DTFT_RST=2
    -DTFT_BL=5
    -DSPI_FREQUENCY=40000000
    -DSPI_READ_FREQUENCY=20000000
    -DLOAD_GLCD=1
    -DLOAD_FONT2=1
    -DLOAD_FONT4=1
    -DLOAD_FONT6=1
    -DLOAD_FONT7=1
    -DLOAD_FONT8=1
    -DLOAD_GFXFF=1
    -DSMOOTH_FONT=1
```

**Important**: The `build_flags` approach for TFT_eSPI avoids needing to edit the library's `User_Setup.h` file. All pin and driver configuration is passed via compile-time defines.

### Alternative: TFT_eSPI User_Setup.h

If preferring to configure TFT_eSPI via its config file instead of build flags, create or modify `User_Setup.h` in the TFT_eSPI library directory:

```cpp
#define ST7789_DRIVER

#define TFT_WIDTH  240
#define TFT_HEIGHT 240

#define TFT_MOSI 13
#define TFT_SCLK 14
#define TFT_CS   15
#define TFT_DC    0
#define TFT_RST   2
#define TFT_BL    5

#define SPI_FREQUENCY       40000000
#define SPI_READ_FREQUENCY  20000000

#define LOAD_GLCD
#define LOAD_FONT2
#define LOAD_FONT4
#define LOAD_FONT6
#define LOAD_FONT7
#define LOAD_FONT8
#define LOAD_GFXFF
#define SMOOTH_FONT
```

### Minimal Firmware Skeleton

A working starting point for `src/main.cpp`:

```cpp
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <LittleFS.h>
#include <TFT_eSPI.h>

TFT_eSPI tft = TFT_eSPI();
ESP8266WebServer server(80);

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

void setup() {
    Serial.begin(115200);

    // Initialize display
    tft.init();
    tft.setRotation(0);  // May need adjustment (0-3)
    tft.fillScreen(TFT_BLACK);

    // Turn on backlight
    pinMode(TFT_BL, OUTPUT);
    analogWrite(TFT_BL, 200);  // 0-255, adjust brightness

    // Show boot message
    tft.setTextColor(TFT_WHITE, TFT_BLACK);
    tft.setTextSize(2);
    tft.setCursor(10, 100);
    tft.println("Booting...");

    // Initialize filesystem
    if (!LittleFS.begin()) {
        tft.println("FS failed!");
        return;
    }

    // Connect WiFi
    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    tft.setCursor(10, 130);
    tft.print("WiFi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        tft.print(".");
    }
    tft.println();
    tft.print("IP: ");
    tft.println(WiFi.localIP().toString());

    // Set up web server
    server.on("/", []() {
        server.send(200, "text/plain", "SmallTV Custom FW");
    });

    server.on("/v.json", []() {
        server.send(200, "application/json",
            "{\"m\":\"SmallTV-Ultra\",\"v\":\"Custom-1.0.0\"}");
    });

    server.begin();
}

void loop() {
    server.handleClient();
    // Add display update logic here
}
```

---

## ESP8266 Constraints and Best Practices

### Memory Management (~80KB Heap)

The ESP8266 has extremely limited RAM. Memory issues are the #1 cause of crashes.

- **Check free heap regularly**: `ESP.getFreeHeap()` — alarm below 10KB
- **Avoid String concatenation**: Each `+` operation allocates new memory. Use `snprintf()` with fixed buffers instead.
- **Avoid large stack allocations**: Keep local arrays small (<1KB). Use `static` or global buffers for large data.
- **Use `F()` macro for string literals**: `server.send(200, F("text/html"), F("<h1>Hello</h1>"))` stores strings in flash instead of RAM.
- **Free resources promptly**: Close files, release buffers as soon as possible.
- **Use streaming responses**: For large HTTP responses, use `server.sendContent()` in chunks rather than building the entire response in memory.

```cpp
// BAD - allocates multiple String objects on heap
String response = "Free: " + String(ESP.getFreeHeap()) + " bytes";

// GOOD - uses stack buffer, no heap allocation
char buf[64];
snprintf(buf, sizeof(buf), "Free: %u bytes", ESP.getFreeHeap());
```

### Single-Threaded Networking

The ESP8266 runs everything on one thread. Long operations block the network stack.

- **Call `yield()` or `delay(1)` in long loops**: Allows WiFi stack to process packets.
- **Keep `loop()` fast**: Target <50ms per iteration.
- **Use non-blocking patterns**: Replace `delay(1000)` with `millis()`-based timers.
- **Display rendering blocks HTTP**: A full 240x240 screen update takes measurable time. Accept brief HTTP latency during redraws.

```cpp
// BAD - blocks for 5 seconds
void loop() {
    updateDisplay();
    delay(5000);
    server.handleClient();
}

// GOOD - non-blocking timer
unsigned long lastUpdate = 0;
void loop() {
    server.handleClient();
    if (millis() - lastUpdate > 5000) {
        updateDisplay();
        lastUpdate = millis();
    }
}
```

### Filesystem (LittleFS/SPIFFS)

- **Total usable space**: ~3MB (with standard 4m1m partition layout)
- **Prefer LittleFS over SPIFFS**: Better wear leveling, directory support, more reliable
- **Budget file space**: Track with `LittleFS.info()` — the `totalBytes` and `usedBytes` fields
- **File names**: Keep short. Paths limited to ~31 characters on SPIFFS.
- **Write carefully**: Flash write cycles are limited (~10K-100K per sector). Avoid writing in tight loops.

### WiFi

- **2.4GHz only**: ESP8266 cannot connect to 5GHz networks
- **No TLS/HTTPS**: HTTP only. For security, use it only on trusted local networks.
- **WiFi Manager pattern**: Start in AP mode if no credentials saved, serve config page, save to filesystem, reboot into STA mode.
- **Reconnection**: WiFi can drop. Check `WiFi.status()` and reconnect periodically.

---

## Display Programming (ST7789 via TFT_eSPI)

### Color Format

RGB565 — 16 bits per pixel. Common color constants from TFT_eSPI:

| Constant | Color |
|----------|-------|
| `TFT_BLACK` | Black (0x0000) |
| `TFT_WHITE` | White (0xFFFF) |
| `TFT_RED` | Red (0xF800) |
| `TFT_GREEN` | Green (0x07E0) |
| `TFT_BLUE` | Blue (0x001F) |
| `TFT_YELLOW` | Yellow (0xFFE0) |

Convert RGB888 to RGB565:
```cpp
uint16_t color565(uint8_t r, uint8_t g, uint8_t b) {
    return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3);
}
```

### Drawing Primitives

```cpp
tft.fillScreen(TFT_BLACK);                    // Clear screen
tft.drawPixel(x, y, color);                   // Single pixel
tft.drawLine(x0, y0, x1, y1, color);          // Line
tft.drawRect(x, y, w, h, color);              // Rectangle outline
tft.fillRect(x, y, w, h, color);              // Filled rectangle
tft.drawCircle(x, y, r, color);               // Circle outline
tft.fillCircle(x, y, r, color);               // Filled circle
tft.setTextColor(fg, bg);                      // Text colors
tft.setTextSize(n);                            // Text scale (1-7)
tft.setCursor(x, y);                           // Text position
tft.print("Hello");                            // Draw text
```

### Displaying JPEG Images

TFT_eSPI includes JPEG decoding support. To display a JPEG from the filesystem:

```cpp
#include <TJpg_Decoder.h>

bool tft_output(int16_t x, int16_t y, uint16_t w, uint16_t h, uint16_t* bitmap) {
    tft.pushImage(x, y, w, h, bitmap);
    return true;
}

void setup() {
    TJpgDec.setJpgScale(1);
    TJpgDec.setCallback(tft_output);
}

void displayJpeg(const char* filename) {
    TJpgDec.drawFsJpg(0, 0, filename);
}
```

### Backlight Control

```cpp
// PWM brightness control (0 = off, 255 = max)
analogWrite(TFT_BL, brightness);

// Simple on/off
digitalWrite(TFT_BL, HIGH);  // On
digitalWrite(TFT_BL, LOW);   // Off
```

### Partial Screen Updates

Redrawing the full 240x240 screen is slow. For animations or frequently changing data, only update the changed region:

```cpp
// Instead of tft.fillScreen() + redraw everything:
tft.fillRect(10, 100, 220, 40, TFT_BLACK);  // Clear just the text area
tft.setCursor(10, 100);
tft.print(newValue);
```

---

## Web Server Implementation

### Basic Setup with ESP8266WebServer

```cpp
#include <ESP8266WebServer.h>
ESP8266WebServer server(80);

void setupServer() {
    // Serve static files from filesystem
    server.serveStatic("/", LittleFS, "/www/");

    // API endpoints
    server.on("/set", handleSet);
    server.on("/v.json", handleVersion);
    server.on("/space.json", handleSpace);

    // File upload
    server.on("/doUpload", HTTP_POST, handleUploadComplete, handleUploadStream);

    // 404
    server.onNotFound(handleNotFound);

    server.begin();
}
```

### Handling the `/set` API Pattern

For GeekMagic API compatibility:

```cpp
void handleSet() {
    String response = "OK";

    if (server.hasArg("theme")) {
        int theme = server.arg("theme").toInt();
        setTheme(theme);
    }
    if (server.hasArg("brt")) {
        int brt = server.arg("brt").toInt();
        setBrightness(brt);
    }
    if (server.hasArg("reboot")) {
        server.send(200, "text/plain", "OK");
        delay(100);
        ESP.restart();
        return;
    }

    server.send(200, "text/plain", response);
}
```

### File Upload Handler

```cpp
File uploadFile;

void handleUploadStream() {
    HTTPUpload& upload = server.upload();
    String dir = server.hasArg("dir") ? server.arg("dir") : "/image/";

    if (upload.status == UPLOAD_FILE_START) {
        String filename = dir + upload.filename;
        uploadFile = LittleFS.open(filename, "w");
    } else if (upload.status == UPLOAD_FILE_WRITE) {
        if (uploadFile) {
            uploadFile.write(upload.buf, upload.currentSize);
        }
    } else if (upload.status == UPLOAD_FILE_END) {
        if (uploadFile) {
            uploadFile.close();
        }
    }
}

void handleUploadComplete() {
    server.send(200, "text/plain", "OK");
}
```

### Gzip-Compressed Responses

Stock firmware serves gzip-compressed HTML. To match this behavior, pre-compress web assets and serve them with the correct header:

```cpp
server.on("/", []() {
    File f = LittleFS.open("/www/index.html.gz", "r");
    server.streamFile(f, "text/html");
    f.close();
});
```

The browser handles decompression automatically when receiving gzip content.

---

## OTA (Over-The-Air) Update Support

### Web-Based OTA (Stock-Compatible)

Implement the `/update` endpoint for firmware uploads:

```cpp
#include <ESP8266HTTPUpdateServer.h>

ESP8266HTTPUpdateServer httpUpdater;

void setup() {
    // ... other setup ...
    httpUpdater.setup(&server, "/update");
    server.begin();
}
```

This provides a web form at `/update` for uploading `.bin` files — compatible with the stock firmware's OTA mechanism.

### ArduinoOTA (Development)

For faster development iteration, add ArduinoOTA support:

```cpp
#include <ArduinoOTA.h>

void setup() {
    ArduinoOTA.setHostname("smalltv-ultra");
    ArduinoOTA.begin();
}

void loop() {
    ArduinoOTA.handle();
    server.handleClient();
}
```

Then upload from PlatformIO:
```bash
pio run --target upload --upload-port smartclock.local
```

---

## Build and Flash Workflow

### Build

```bash
cd my-smalltv-firmware
pio run
```

Output: `.pio/build/esp12e/firmware.bin`

### Flash via OTA (Recommended for Development)

1. Ensure the device is running firmware with an `/update` page (stock or custom with HTTPUpdateServer).
2. Navigate to `http://{IP}/update` in a browser.
3. Upload the `.bin` file.
4. Wait for reboot (~30-60 seconds).

Or use curl:
```bash
curl -F "image=@.pio/build/esp12e/firmware.bin" http://{IP}/update
```

### Flash via UART (Recovery)

If OTA is unavailable (bricked device, corrupted firmware):

1. Connect USB-UART adapter to PCB GPIO pin holes (TX→RX, RX→TX, GND→GND, 3.3V→3.3V).
2. Hold GPIO0 to GND to enter flash mode.
3. Flash:
   ```bash
   pio run --target upload --upload-port /dev/ttyUSB0
   ```
4. Release GPIO0, power cycle.

### Upload Filesystem

To upload web assets and other files to LittleFS:

```bash
# Place files in data/ directory in project root
pio run --target uploadfs
```

For OTA filesystem upload, implement a filesystem update handler or upload files individually via the `/doUpload` endpoint.

---

## Debugging

### Serial Monitor

```bash
pio device monitor --baud 115200
```

Add debug output in code:
```cpp
Serial.printf("Free heap: %u\n", ESP.getFreeHeap());
Serial.printf("WiFi status: %d\n", WiFi.status());
```

### Web-Based Debug Log

Implement a `/log` endpoint (like bvweerd does):

```cpp
String logBuffer = "";

void logMsg(const String& msg) {
    logBuffer += msg + "\n";
    if (logBuffer.length() > 4096) {
        logBuffer = logBuffer.substring(logBuffer.length() - 4096);
    }
    Serial.println(msg);
}

// In server setup:
server.on("/log", []() {
    server.send(200, "text/plain", logBuffer);
});
```

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Blank screen | Wrong SPI pins or missing RST/DC | Verify pin mapping matches hardware |
| White screen | Display init failed | Check SPI mode (must be MODE3), verify CS pin |
| Watchdog reset | `loop()` too slow, no `yield()` | Add `yield()` in long operations |
| Out of memory | String concatenation, large buffers | Use `F()` macro, fixed-size buffers, check heap |
| WiFi won't connect | 5GHz network, wrong credentials | Confirm 2.4GHz network, check SSID/password |
| OTA upload fails | Not enough free flash | Use 4m1m partition, check firmware size <~1MB |
| "Magic Byte" error | Wrong .bin file or corrupted download | Re-download, check MD5, disable antivirus |

---

## Project Structure Reference

Recommended project layout:

```
my-smalltv-firmware/
├── platformio.ini           # Build configuration
├── src/
│   ├── main.cpp             # Entry point, setup(), loop()
│   ├── display.h/cpp        # Display rendering functions
│   ├── webserver.h/cpp      # HTTP server and API handlers
│   ├── wifi_manager.h/cpp   # WiFi AP/STA mode management
│   └── config.h/cpp         # Settings storage (LittleFS JSON)
├── data/                    # Files uploaded to LittleFS
│   └── www/
│       ├── index.html       # Web console
│       ├── settings.js      # Client-side JavaScript
│       └── style.css        # Styling
└── lib/                     # Local libraries (if needed)
```

---

## Key Resources

- **PlatformIO ESP8266 docs**: https://docs.platformio.org/en/latest/platforms/espressif8266.html
- **TFT_eSPI library**: https://github.com/Bodmer/TFT_eSPI
- **TJpg_Decoder**: https://github.com/Bodmer/TJpg_Decoder
- **ESP8266 Arduino core**: https://arduino-esp8266.readthedocs.io/
- **bvweerd reference firmware**: https://github.com/bvweerd/geekmagic-tv-esp8266
- **Hardware teardown**: https://puddleofcode.com/story/my-own-geekmagic-smalltv/
