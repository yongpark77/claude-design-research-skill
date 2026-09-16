---
name: design-research
description: Read-only research of public market and competitor UX/UI patterns that feeds product-design framing, flows, ideation, and review. Invoke explicitly for design research, competitive UX analysis, or interaction-pattern research.
disable-model-invocation: true
user-invocable: true
argument-hint: [리서치 질문 또는 비교 기준]
allowed-tools: Read, Grep, Glob, WebSearch, WebFetch, mcp__Claude_Browser__navigate, mcp__Claude_Browser__get_page_text, mcp__Claude_Browser__read_page
---

# Design research

Research question: **$ARGUMENTS**

This skill is explicit-invocation only and read-only. It produces a report in the chat for the `product-design` skill to use. It does not publish, save, share, or modify anything.

## Scope

- Study public market and competitor products for UX/UI patterns relevant to the question.
- Analyze relevant screens, interactions, information architecture, and user flows.
- Extract recurring patterns and counter-examples, and identify differentiation opportunities.
- For each example, state why it applies to the current product and why it should not be copied as-is.
- Record the source URL and the date observed for every claim.

## Method

1. Restate the research question and the comparison criteria. If the question is missing or too broad, ask one focused question before searching.
2. Collect representative examples and counter-examples with WebSearch and WebFetch. Use the built-in browser read tools only to read a page that WebFetch cannot render. Do not log in, click through consent flows, submit forms, or change any site state.
3. Extract repeated UX patterns. Exclude patterns unrelated to the user's stated problem.
4. Derive applicable principles and risks for the current product, using the project design system and shipped patterns as the frame of reference.
5. Return the report below in the chat. Do not write files.

## Report format

1. **Research question and criteria**
2. **Summary**: three to five lines of key findings.
3. **Examples**: per product, the screens or flows observed, the pattern, and the date observed.
4. **Recurring patterns and counter-examples**
5. **Applicable principles and risks**: what transfers to the current product, what does not, and why.
6. **Inputs for product-design**: bullets grouped for `frame`, `flow`, `ideate`, and `review`.
7. **Sources**: one clickable link per bullet.

Describe visuals in words. Do not embed or hotlink images. Mark any claim you could not verify as unverified.

## Prohibited

Never do any of the following as part of this skill, even if a prior version or another document describes it:

1. Publish to Notion or any external document tool.
2. Place references into Figma or FigJam.
3. Create or share external documents.
4. Quit, restart, or close the user's browser, tabs, or apps.
5. Change any user state in a browser or app, including sign-in, consent, or settings.
6. Modify code.
7. Modify designs.
8. Modify Figma files.
9. Modify local files or write reports to disk.
10. Log in, pay, submit, post, or send messages.
11. Collect credentials, secrets, or customer PII.

If a finding suggests a follow-up that needs one of these actions, list it under "Suggested next steps" and stop. The user decides.
