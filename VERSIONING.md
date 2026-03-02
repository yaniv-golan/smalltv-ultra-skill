# Versioning Strategy

This repository ships two independent deliverables:

1. **Skill/Plugin** (`.claude-plugin`, `skills/`)
2. **Local MCP bundle** (`mcp/smalltv-local`, `.mcpb`)

Both follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`), but they are
versioned independently.

## Skill/Plugin Version

- Source of truth:
  - `.claude-plugin/plugin.json` -> `version`
  - `.claude-plugin/marketplace.json` -> `plugins[0].version`
- Tag format:
  - `skill-vX.Y.Z` (example: `skill-v1.2.0`)
- Bump rules:
  - `MAJOR`: breaking behavior/prompt contract changes
  - `MINOR`: backward-compatible feature additions
  - `PATCH`: fixes/docs/safe internal improvements

## MCP Bundle Version

- Source of truth:
  - `mcp/smalltv-local/server.d/server.meta.json` -> `version`
- Tag format:
  - `mcp-vX.Y.Z` (example: `mcp-v0.2.1`)
- Release artifact:
  - `smalltv-local-mcp-X.Y.Z.mcpb`
  - `SHA256SUMS`

## CI/CD Behavior

- `validate-mcpb.yml`
  - Runs on pull requests and pushes to `main`
  - Validates and builds the MCP bundle
- `release-mcpb.yml`
  - Runs on `mcp-v*` tags and `workflow_dispatch`
  - Builds `.mcpb`, generates `SHA256SUMS`, and publishes assets
  - Enforces tag/version consistency for tag-triggered runs

## Release Checklist

### Skill Release

1. Update `.claude-plugin/plugin.json` version
2. Update `.claude-plugin/marketplace.json` plugin version
3. Update `CHANGELOG.md`
4. Create tag `skill-vX.Y.Z`

### MCP Release

1. Update `mcp/smalltv-local/server.d/server.meta.json` version
2. (Optional) Rebuild local bundle for testing
3. Update `CHANGELOG.md` if user-facing
4. Create tag `mcp-vX.Y.Z`
5. Verify GitHub Release contains:
   - `.mcpb`
   - `SHA256SUMS`
