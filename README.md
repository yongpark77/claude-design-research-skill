# design-research

Explicit-invocation, read-only skill that researches public market and competitor UX/UI patterns and
returns a report in the chat for the `product-design` skill to use. Shared by Claude Code
(`~/.claude/skills/design-research`) and Codex (`~/.agents/skills/design-research` is a symlink to it).

## Usage

```
/design-research SaaS 온보딩 UX 트렌드 2026
```

## What it does

Restates the question, collects public examples with WebSearch and WebFetch, extracts recurring
patterns and counter-examples, and returns principles and risks for the current product with a
dated source link per claim.

## What it never does

It does not publish to Notion or any other service, write files, touch Figma, change browser or app
state, log in, or collect credentials or PII. Earlier versions uploaded reports to Notion and closed
Chrome tabs; that behavior is retired and must not be reintroduced.

## Legacy file

`save_to_notion.sh` is retained from an earlier version for repository history and compatibility.
The current skill does not invoke it, request its credentials, or treat it as part of the workflow.
