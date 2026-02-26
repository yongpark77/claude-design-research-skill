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

1. Copy `SKILL.md` to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/design-research
cp SKILL.md ~/.claude/skills/design-research/
```

2. Copy `save_to_notion.sh` to your project directory and make it executable:

```bash
cp save_to_notion.sh /path/to/your/project/
chmod +x save_to_notion.sh
```

3. Create a `.notion_credentials` file in your project root:

```bash
NOTION_API_KEY=your_notion_api_key_here
NOTION_PAGE_ID=your_notion_page_id_here
```

> **Note:** `.notion_credentials` is in `.gitignore` and should never be committed. Each user must create their own.

### Getting Notion credentials

- **API Key**: Create an integration at [Notion Developers](https://www.notion.so/my-integrations) and copy the Internal Integration Secret.
- **Page ID**: Open the target Notion page in browser. The 32-character hex string at the end of the URL is the Page ID.
- Don't forget to **connect** your integration to the target page (Page → ··· → Connections → Add).

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- Playwright MCP server configured in Claude Code
- Python 3 (for `save_to_notion.sh`)
- Notion API integration with page access
