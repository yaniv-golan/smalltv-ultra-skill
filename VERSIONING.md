# Versioning Strategy

This repository ships two independent deliverables through separate
distribution channels:

1. **Plugin** (`.claude-plugin/`, `skills/`) — installed via Claude marketplace
2. **MCP bundle** (`mcp/smalltv-local/`, `.mcpb`) — installed as a Claude Extension

Both follow **Semantic Versioning** (`MAJOR.MINOR.PATCH`) and are versioned
independently because they can be installed and updated separately.

## Plugin Version

The plugin version covers **all** plugin content: manifest files, every skill
in `skills/`, and any bundled documentation or scripts.

- Source of truth:
  - `.claude-plugin/plugin.json` → `version`
  - `.claude-plugin/marketplace.json` → `plugins[0].version` (must match)
- Tag format:
  - `skill-vX.Y.Z` (example: `skill-v0.2.0`)
- Bump rules:
  - `MAJOR`: breaking behavior or prompt-contract changes in any skill
  - `MINOR`: new skill added, or backward-compatible feature additions to
    existing skills
  - `PATCH`: fixes, docs, safe internal improvements

### Skills Do Not Carry Independent Versions

The `version` field in SKILL.md YAML frontmatter is optional and **omitted**
in this project. The plugin version is the single version for all plugin
content.

Rationale:

- Skills ship inside the plugin — they are not independently installable.
- The plugin version already identifies each release.
- `CHANGELOG.md` tracks per-skill changes with enough granularity.
- Independent skill versions create confusing mismatches (e.g. a skill at
  `1.0.0` inside a plugin at `0.2.0`).

When recording changes in CHANGELOG.md, prefix entries with the skill name
so readers know which skill was affected:

```
## [skill-0.2.0] - 2026-03-02

### Added
- **smalltv-mcp-tools**: New skill for MCP-based device control workflows
```

## MCP Bundle Version

- Source of truth:
  - `mcp/smalltv-local/server.d/server.meta.json` → `version`
- Tag format:
  - `mcp-vX.Y.Z` (example: `mcp-v0.4.5`)
- Release artifact:
  - `smalltv-local-mcp-X.Y.Z.mcpb`
  - `SHA256SUMS`
- Bump rules:
  - `MAJOR`: breaking tool interface changes (renamed tools, removed
    parameters, changed output schema)
  - `MINOR`: new tools, new optional parameters, new resources/prompts
  - `PATCH`: bug fixes, doc improvements, internal script changes

## Cross-Deliverable Changes

Some changes touch both deliverables (e.g. updating the canonical
`references/` docs that feed into both the skill and the MCP resources).
In that case, bump **both** versions and tag separately:

```bash
git tag skill-v0.3.0
git tag mcp-v0.5.0
```

## CI/CD Behavior

- `validate-mcpb.yml`
  - Runs on pull requests and pushes to `main`
  - Validates and builds the MCP bundle
- `release-mcpb.yml`
  - Runs on `mcp-v*` tags and `workflow_dispatch`
  - Builds `.mcpb`, generates `SHA256SUMS`, and publishes assets
  - Enforces tag/version consistency for tag-triggered runs

## Release Checklist

### Skill/Plugin Release

1. Update `.claude-plugin/plugin.json` version
2. Update `.claude-plugin/marketplace.json` plugin version
3. Update `CHANGELOG.md` (prefix entries with skill name)
4. Verify no SKILL.md files contain a `version` field
5. Create tag `skill-vX.Y.Z`

### MCP Release

1. Update `mcp/smalltv-local/server.d/server.meta.json` version
2. (Optional) Rebuild local bundle for testing
3. Update `CHANGELOG.md` if user-facing
4. Create tag `mcp-vX.Y.Z`
5. Verify GitHub Release contains:
   - `.mcpb`
   - `SHA256SUMS`
