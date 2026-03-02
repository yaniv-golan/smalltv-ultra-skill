# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

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
