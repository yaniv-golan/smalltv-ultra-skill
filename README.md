[![Claude Cowork](https://img.shields.io/badge/Claude_Cowork-D97757?logo=claude&logoColor=fff)](https://claude.com/plugins)
[![Claude Code](https://img.shields.io/badge/Claude_Code-555?logo=claude&logoColor=fff)](https://code.claude.com/docs/en/plugins)
[![CI](https://github.com/yaniv-golan/smalltv-ultra-skill/actions/workflows/validate-mcpb.yml/badge.svg)](https://github.com/yaniv-golan/smalltv-ultra-skill/actions/workflows/validate-mcpb.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![MCP Bash Framework](https://img.shields.io/badge/MCP-MCP_Bash_Framework-green?logo=modelcontextprotocol)](https://github.com/yaniv-golan/mcp-bash-framework)

# SmallTV Ultra Skill

A [Claude](https://claude.ai) skill for controlling, customizing, and developing firmware for the **GeekMagic SmallTV Ultra** — an ESP8266-based IoT device with a 240x240 TFT display.


## What is the SmallTV Ultra?

The [GeekMagic SmallTV Ultra](https://geekmagic.com/products/geekmagic-ultra-4/) is a tiny WiFi-connected display powered by an ESP8266 with a 1.5" 240x240 IPS screen. Out of the box it shows weather, time, crypto prices, and a photo album — all controlled via an HTTP API with no authentication.


## What This Skill Covers

| Path | Description |
|------|-------------|
| **Control** | Use the stock firmware HTTP API — change themes, adjust brightness, upload images/GIFs, configure weather, and more |
| **Custom Content** | Generate and push 240x240 images/GIFs to the display — dashboards, stats, notifications, art |
| **Alternative Firmware** | Install community firmware (bvweerd, ESPHome, Tasmota) with guided safety checks and rollback |
| **Custom Firmware** | Write your own ESP8266 firmware from scratch with PlatformIO, TFT_eSPI, and OTA flashing |

The skill includes complete device reference documentation, API details, and step-by-step guides for each path.

## Choose Your Setup

Use this quick guide first:

| Setup | Best for | Can reach SmallTV directly? | What to use |
|---|---|---|---|
| **Claude Code + skill** | Local terminal workflow | **Yes** | Install skill from marketplace |
| **Claude Desktop (Chat mode) + skill** | Desktop chat workflow | **No** | Use local proxy + tunnel bridge |
| **Claude Desktop (Cowork mode) + skill** | Cowork VM workflow | **No** (in this project setup) | Use local proxy + tunnel bridge |
| **Claude Desktop (Chat or Cowork) + local MCPB** | Desktop with local MCP tools | **Yes** (via local MCP on your machine) | Install prebuilt `.mcpb` |

If you are unsure, pick:
1. **Claude Code + skill** for easiest direct control
2. **Desktop + MCPB** for secure local MCP access without exposing the raw device API

## Installation

### Claude Desktop (recommended)

1. Open **Claude Desktop**
2. Go to **Customize** > **Browse plugins** > **Personal**
3. Click the **+** button, then **"Add marketplace from GitHub"**
4. Enter `yaniv-golan/smalltv-ultra-skill`

Alternatively, click **+** > **"Upload plugin"** to install from a local copy.

### Claude Code (CLI)

```bash
# Add the marketplace and install
claude plugin marketplace add yaniv-golan/smalltv-ultra-skill
claude plugin install geekmagic-smalltv-ultra

# Or load from a local copy (no install needed)
claude --plugin-dir /path/to/smalltv-ultra-skill
```

## Runtime and Network Reachability

This plugin can be used from Claude Desktop (Chat/Cowork modes) and Claude Code. The key difference is whether that runtime can directly reach your SmallTV private LAN IP (for example `192.168.x.x`).

| Runtime | Where it runs | Can reach private LAN device directly? |
|---|---|---|
| **Claude Desktop (Chat mode)** | Anthropic-managed runtime | **No** |
| **Claude Desktop (Cowork mode)** | Local VM on your machine | **No** (in this project setup) |
| **Claude Code (CLI)** | In your terminal on your machine | **Yes**, if your machine can reach the device |
| **Claude cloud code execution** | Anthropic-managed cloud VM | **No** (private LAN is not directly routable) |

If your runtime cannot reach LAN directly, use a bridge (local MCP server or local proxy+tunnel).

## Secure Quick Tunnel

If your runtime cannot reach the device LAN directly, you can run a local token-protected proxy and tunnel it with `cloudflared`. See the [Secure Quick Tunnel guide](docs/secure-tunnel.md) for full setup instructions.

## Local MCP Server Option (mcp-bash)

This repo also includes a local MCP server project at [`mcp/smalltv-local`](mcp/smalltv-local), built with [`mcp-bash`](https://github.com/yaniv-golan/mcp-bash-framework).

Use this when you want Claude or any MCP-capable app/client to call your SmallTV through your local machine without exposing the device directly.

Recommended install path (simplest):

1. Download the latest `.mcpb` from [GitHub Releases](https://github.com/yaniv-golan/smalltv-ultra-skill/releases/latest).
2. Install the bundle in your MCPB-compatible client.
3. Provide device IP in the install/user-config prompt.

See [`mcp/smalltv-local/README.md`](mcp/smalltv-local/README.md) for details, fallback behavior, and developer-only setup.

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

## Versioning

See [VERSIONING.md](VERSIONING.md) for SemVer rules, tag naming (`skill-v*` and `mcp-v*`), and MCP release workflow behavior.

## Disclaimer

This project is unofficial and not affiliated with, endorsed by, or sponsored by GeekMagic. "GeekMagic" and "SmallTV" are trademarks of their respective owners.

## License

[MIT](LICENSE) &copy; 2026 Yaniv Golan
