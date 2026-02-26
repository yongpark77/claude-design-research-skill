# design-research

A [Claude Code skill](https://code.claude.com/docs/en/skills.md) that automates design research and generates Notion reports.

## What it does

1. Saves and closes Chrome tabs (for Playwright compatibility)
2. Performs web research using WebSearch, WebFetch, and Playwright
3. Collects and validates images (HTTP HEAD check, format compatibility)
4. Writes a structured Markdown report
5. Uploads to Notion via `save_to_notion.sh`
6. Restores Chrome tabs

## Usage

```
/design-research SaaS 온보딩 UX 트렌드 2026
/design-research 모바일 앱 네비게이션 패턴 분석
```

## Installation

Copy `SKILL.md` to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/design-research
cp SKILL.md ~/.claude/skills/design-research/
```

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- Notion API credentials (`.notion_credentials` file)
- `save_to_notion.sh` script for Notion upload
- Playwright MCP server configured in Claude Code
