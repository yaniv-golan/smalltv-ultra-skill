# Contributing

Thanks for your interest in improving the SmallTV Ultra skill!

## Reporting Issues

Open an issue on GitHub with:
- What you were trying to do
- What happened instead
- Your device firmware version (from `/v.json`)
- Whether you're using Claude Desktop/Cowork or Claude Code CLI

## Submitting Changes

1. Fork the repo and create a branch
2. Make your changes
3. Test locally (see below)
4. Open a pull request with a clear description of what changed and why

## Testing Locally

Use `--plugin-dir` to load your local copy of the plugin:

```bash
claude --plugin-dir /path/to/your/smalltv-ultra-skill
```

Then interact with Claude to verify your changes work as expected. If your changes involve device interaction, test against an actual SmallTV Ultra device.

## Documentation Architecture

This project ships two complementary layers:

- **Skills** (in [`skills/`](skills/)) provide workflow orchestration logic — how to use the device, safety rules, multi-step patterns, and domain expertise. Skills are loaded by Claude on demand.
- **MCP server** (in [`mcp/smalltv-local/`](mcp/smalltv-local/)) provides tool connectivity — the actual HTTP calls to the device. The server includes built-in instructions, resources, and a prompt so MCP clients can discover capabilities without the skill layer.

Both layers share the same canonical documentation: the skill `references/` files are the single source of truth, and the MCP resource docs are generated from them via [`scripts/sync_skill_docs_to_mcp.py`](scripts/sync_skill_docs_to_mcp.py). CI enforces freshness so the two never drift apart.

When editing device documentation, always update the skill `references/` files first, then run the sync script:

```bash
python3 scripts/sync_skill_docs_to_mcp.py
```

## What to Contribute

- Bug fixes and corrections to device reference docs
- New API endpoints or firmware version updates
- Improved safety checks or error handling guidance
- Better examples for custom content generation
- Support for new alternative firmware options

## Style

- Keep the SKILL.md focused and actionable — it's a working reference, not a tutorial
- Reference files in `references/` hold the detailed documentation
- Test any API endpoint examples against a real device before submitting
