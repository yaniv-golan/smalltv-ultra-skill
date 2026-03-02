# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.4.5] - 2026-03-02

### Changed
- Unified env var to `SMALLTV_IP` everywhere — user_config key, env_map, tool scripts, and docs all use the same name. Reverted unnecessary `setup.sh` changes from 0.4.4.

## [0.4.3] - 2026-03-02

### Fixed
- Model no longer wastes a round trip calling tools without `device_ip` — parameter description changed from "Optional device IP. Falls back to SMALLTV_DEVICE_IP." to "Device IP address (e.g. 192.168.5.253). Always pass this if known."

## [0.4.2] - 2026-03-02

### Changed
- Server instructions rewritten to be self-contained — the model no longer depends on reading MCP resources (which are user-selectable, not model-initiated) for critical API knowledge
- Added complete `/set?` parameter reference, JSON read endpoints, file management, and theme table directly in server instructions
- Added explicit "NOT SUPPORTED" section: no text display endpoint exists, custom text requires image rendering workflow
- Added "Do not probe unknown parameters" guidance to prevent speculative endpoint guessing
- Resources section reframed as "user-selectable" supplementary context

## [0.4.1] - 2026-03-02

### Fixed
- Device-unreachable errors now return structured `upstream_unreachable` error instead of generic "Tool output does not satisfy outputSchema" — `outputSchema` in all tools updated to accept both success and error shapes
- Tool timeout race conditions: `timeoutSecs` now exceeds curl `--max-time` in all tools so our error handler runs before mcp-bash kills the process
- Stale `smalltv-http-request` references in `get-started` prompt and `smalltv-get-device-info` description

### Changed
- Timeout buffer per tool: get-device-info 10s, read 12s, write 15s, upload-file 45s, upload-firmware 150s

## [0.4.0] - 2026-03-02

### Changed
- **Breaking**: Replaced `smalltv-http-request` with two granular tools:
  - `smalltv-read` — GET-only, read-only, blocks write endpoints (`readOnlyHint: true`)
  - `smalltv-write` — all HTTP methods, all endpoints (`openWorldHint: true`)
- Server instructions updated with tool-per-task endpoint table

### Removed
- `smalltv-http-request` tool (replaced by `smalltv-read` and `smalltv-write`)

## [0.3.1] - 2026-03-02

### Added
- New `smalltv-upload-firmware` tool for flashing .bin/.bin.gz firmware files via /update endpoint
- Requires explicit `confirm=true` parameter — tool refuses to run without user approval
- Marked with `destructiveHint: true` annotation so clients can show confirmation UI

## [0.3.0] - 2026-03-02

### Added
- New `smalltv-upload-file` tool for uploading JPG/GIF images via multipart form data (fixes inability to upload binary files through the string-based `smalltv-http-request` body)
- File validation: extension check (.jpg/.jpeg/.gif only), firmware rejection, dir whitelist (/image/, /gif)

### Changed
- Server instructions updated to direct uploads to `smalltv-upload-file` and warn against using `smalltv-http-request` for binary data

## [0.2.0] - 2026-03-02

### Added
- Resource annotations (`priority: 1.0`, `audience: ["assistant"]`) on API reference and safety guide resources to signal clients to auto-include them in context
- Tool annotations: `readOnlyHint`/`destructiveHint` on `smalltv-get-device-info`, `openWorldHint` on `smalltv-http-request`

### Changed
- Upgraded mcp-bash framework from 1.1.2 to 1.1.3 (adds resource annotation support)

## [0.1.0] - 2026-03-02

### Added
- Skill with four workflow paths: device control, custom content, alternative firmware, custom firmware
- Complete HTTP API reference for stock firmware
- Alternative firmware installation guides (bvweerd, ESPHome, Tasmota)
- Custom firmware development guide (PlatformIO + TFT_eSPI)
- Device IP persistence across sessions via `.claude/geekmagic-smalltv-ultra.local.md`
- Safety checks and destructive endpoint warnings
- WiFi recovery instructions
- Local MCP server (`mcp/smalltv-local`) built with mcp-bash, with two tools (`smalltv-get-device-info`, `smalltv-http-request`), MCP resources, prompt, and server instructions
- Token-authenticated secure proxy (`scripts/smalltv-secure-proxy.py`) with auto-detection and cloudflared tunnel support
- CI/CD workflows for MCPB validation and tag-triggered releases to GitHub Releases
- Script to generate MCP resource docs from canonical skill references (`scripts/sync_skill_docs_to_mcp.py`)
- VERSIONING.md documenting independent SemVer for skill and MCP bundle
- Secure tunnel guide at `docs/secure-tunnel.md`
- Documentation architecture section in CONTRIBUTING.md
- README badges (Claude Cowork, Claude Code, CI, MCP Bash Framework)
