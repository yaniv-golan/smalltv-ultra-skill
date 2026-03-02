[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# SmallTV Ultra Skill

A [Claude](https://claude.ai) skill for controlling, customizing, and developing firmware for the **GeekMagic SmallTV Ultra** — an ESP8266-based IoT device with a 240x240 TFT display.

<!-- ![SmallTV Ultra device](docs/device-photo.jpg) -->

## What is the SmallTV Ultra?

The [GeekMagic SmallTV Ultra](https://github.com/GeekMagicClock/smalltv-ultra) is a tiny WiFi-connected display powered by an ESP8266 with a 1.5" 240x240 IPS screen. Out of the box it shows weather, time, crypto prices, and a photo album — all controlled via an HTTP API with no authentication.

<!-- ![SmallTV Ultra on a desk](docs/device-desk.jpg) -->

## What This Skill Covers

| Path | Description |
|------|-------------|
| **Control** | Use the stock firmware HTTP API — change themes, adjust brightness, upload images/GIFs, configure weather, and more |
| **Custom Content** | Generate and push 240x240 images/GIFs to the display — dashboards, stats, notifications, art |
| **Alternative Firmware** | Install community firmware (bvweerd, ESPHome, Tasmota) with guided safety checks and rollback |
| **Custom Firmware** | Write your own ESP8266 firmware from scratch with PlatformIO, TFT_eSPI, and OTA flashing |

The skill includes complete device reference documentation, API details, and step-by-step guides for each path.

## Installation

### Claude Desktop / Cowork (recommended)

1. Open **Claude Desktop** or **Cowork**
2. Go to **Settings** > **Plugins** > **Browse**
3. Search for **"SmallTV Ultra"**
4. Click **Install**

Or upload the plugin directory manually via **Settings** > **Plugins** > **Upload**.

### Claude Code (CLI)

```bash
# Install from the plugin directory
claude plugin add yaniv-golan/smalltv-ultra-skill

# Or install from a local copy
claude --plugin-dir /path/to/smalltv-ultra-skill
```

## Device Setup

### Finding Your Device IP

The SmallTV Ultra displays its IP address:
- **On boot** — unplug and replug the USB-C cable (there is no battery); the IP appears on the boot screen
- **On the Weather Clock theme** — the IP briefly shows between weather data rotations

### First-Time Configuration

Once you have the IP, just tell Claude:

> "Set up my SmallTV Ultra at 192.168.1.100"

The skill will verify the device, save the IP for future sessions, and you're ready to go. If the device IP changes later, just provide the new one.

### WiFi Recovery

If the device loses WiFi connectivity:
1. Power cycle 3 times rapidly (plug in, unplug when progress bar shows, repeat)
2. Connect to the **"GIFTV"** hotspot the device creates
3. Navigate to `http://192.168.4.1` and configure your WiFi credentials

## Resources

- [Stock firmware repo](https://github.com/GeekMagicClock/smalltv-ultra) — official GeekMagic firmware and documentation
- [bvweerd's open-source firmware](https://github.com/bvweerd/geekmagic-tv-esp8266) — alternative firmware with text API
- [Home Assistant HACS integration](https://github.com/crisz/hass-geekmagic-smalltv) — push HA dashboards to the display

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on reporting issues, submitting PRs, and testing locally.

## License

[MIT](LICENSE) &copy; 2026 Yaniv Golan
