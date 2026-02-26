#!/bin/bash
# DesignHelp Research → Notion 자동화
# 사용법: ./save_to_notion.sh [research_file.md]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Load credentials
source .notion_credentials

if [ "$NOTION_PAGE_ID" = "여기에_페이지ID_입력" ]; then
    echo "❌ .notion_credentials에서 NOTION_PAGE_ID를 설정해주세요."
    echo "   Notion 페이지 URL 끝의 32자리 hex 값입니다."
    exit 1
fi

TODAY=$(date +"%Y-%m-%d")

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 파일 지정
if [ $# -eq 1 ]; then
    REPORT_FILE="$1"
else
    echo -e "${RED}❌ 사용법: ./save_to_notion.sh <report_file.md>${NC}"
    exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo -e "${RED}❌ 파일을 찾을 수 없습니다: $REPORT_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  DesignHelp Research → Notion (자동)   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}[1/2] Markdown을 Notion 블록으로 변환 중...${NC}"

# Python script to convert markdown and send to Notion
python3 - "$REPORT_FILE" "$NOTION_API_KEY" "$NOTION_PAGE_ID" "$TODAY" <<'PYTHON'
import sys
import json
import re
import urllib.request
import urllib.error

markdown_file = sys.argv[1]
api_key = sys.argv[2]
parent_page_id = sys.argv[3]
today = sys.argv[4]

with open(markdown_file, 'r', encoding='utf-8') as f:
    content = f.read()

HEADERS = {
    "Authorization": f"Bearer {api_key}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}


def parse_inline(text):
    """Parse inline markdown (bold, italic, links, mixed) into Notion rich_text array."""
    rich_text = []
    pos = 0
    s = text

    while pos < len(s):
        # Try bold+link: **[text](url)**
        m = re.match(r'\*\*\[([^\]]+)\]\(([^)]+)\)\*\*', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(1), "link": {"url": m.group(2)}},
                "annotations": {"bold": True}
            })
            pos += m.end()
            continue

        # Try bold: **text**
        m = re.match(r'\*\*(.*?)\*\*', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(1)},
                "annotations": {"bold": True}
            })
            pos += m.end()
            continue

        # Try italic: *text*
        m = re.match(r'\*([^*]+?)\*', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(1)},
                "annotations": {"italic": True}
            })
            pos += m.end()
            continue

        # Try link: [text](url)
        m = re.match(r'\[([^\]]+)\]\(([^)]+)\)', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(1), "link": {"url": m.group(2)}}
            })
            pos += m.end()
            continue

        # Try inline code: `text`
        m = re.match(r'`([^`]+)`', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(1)},
                "annotations": {"code": True}
            })
            pos += m.end()
            continue

        # Plain text: consume until next special character
        m = re.match(r'[^*\[`]+', s[pos:])
        if m:
            rich_text.append({
                "type": "text",
                "text": {"content": m.group(0)}
            })
            pos += m.end()
            continue

        # Fallback: consume one character
        rich_text.append({
            "type": "text",
            "text": {"content": s[pos]}
        })
        pos += 1

    return rich_text if rich_text else [{"type": "text", "text": {"content": text}}]


def make_block(block_type, rich_text):
    """Create a Notion block of the given type with rich_text content."""
    return {
        "object": "block",
        "type": block_type,
        block_type: {"rich_text": rich_text}
    }


def make_image_block(url, caption=""):
    """Create a Notion image block from external URL."""
    block = {
        "object": "block",
        "type": "image",
        "image": {
            "type": "external",
            "external": {"url": url}
        }
    }
    if caption:
        block["image"]["caption"] = parse_inline(caption)
    return block


def parse_table_row(line):
    """Parse a markdown table row into a list of cell strings."""
    # Strip leading/trailing |, then split by |
    line = line.strip()
    if line.startswith('|'):
        line = line[1:]
    if line.endswith('|'):
        line = line[:-1]
    return [cell.strip() for cell in line.split('|')]


def is_table_separator(line):
    """Check if line is a markdown table separator (|---|---|)."""
    stripped = line.strip()
    return bool(re.match(r'^[\|\s\-:]+$', stripped)) and '---' in stripped


def make_table_block(table_lines):
    """Convert markdown table lines into a Notion table block with children."""
    # Filter out separator rows
    data_lines = [l for l in table_lines if not is_table_separator(l)]
    if not data_lines:
        return None

    # Parse all rows
    rows = [parse_table_row(l) for l in data_lines]

    # Determine column count (max across all rows)
    col_count = max(len(row) for row in rows)

    # Normalize row lengths
    for row in rows:
        while len(row) < col_count:
            row.append('')

    # Build table_row children
    table_rows = []
    for row in rows:
        cells = [parse_inline(cell) if cell else [{"type": "text", "text": {"content": ""}}] for cell in row]
        table_rows.append({
            "type": "table_row",
            "table_row": {"cells": cells}
        })

    return {
        "object": "block",
        "type": "table",
        "table": {
            "table_width": col_count,
            "has_column_header": True,
            "has_row_header": False,
            "children": table_rows
        }
    }


# Convert markdown to Notion blocks
blocks = []
lines = content.split('\n')
page_title = f"Research Report - {today}"  # default

i = 0
in_callout_section = False

while i < len(lines):
    line = lines[i]
    stripped = line.strip()

    if not stripped:
        i += 1
        continue

    # H1: Page title (extract, don't create block)
    if stripped.startswith('# '):
        page_title = stripped[2:].strip()
        i += 1
        continue

    # Horizontal rule
    if stripped == '---' or stripped == '***' or stripped == '___':
        in_callout_section = False
        blocks.append({
            "object": "block",
            "type": "divider",
            "divider": {}
        })
        i += 1
        continue

    # H2: Section headers
    if stripped.startswith('## '):
        section = stripped[3:].strip()
        lower = section.lower()
        if any(kw in lower for kw in ['takeaway', 'insight', '핵심', '시사점', '결론']):
            in_callout_section = True
        else:
            in_callout_section = False
        blocks.append(make_block("heading_2", parse_inline(section)))
        i += 1
        continue

    # H3: Sub-section headers
    if stripped.startswith('### '):
        title = stripped[4:].strip()
        blocks.append(make_block("heading_3", parse_inline(title)))
        i += 1
        continue

    # Table: lines starting with |
    if stripped.startswith('|') and '|' in stripped[1:]:
        table_lines = []
        while i < len(lines):
            l = lines[i].strip()
            if l.startswith('|') and '|' in l[1:]:
                table_lines.append(l)
                i += 1
            else:
                break
        table_block = make_table_block(table_lines)
        if table_block:
            blocks.append(table_block)
        continue

    # Image: ![alt](url)
    m = re.match(r'^!\[([^\]]*)\]\(([^)]+)\)', stripped)
    if m:
        alt_text = m.group(1)
        image_url = m.group(2)
        blocks.append(make_image_block(image_url, alt_text))
        i += 1
        continue

    # Callout items in insight/takeaway sections
    if in_callout_section and re.match(r'^\d+\.', stripped):
        text = re.sub(r'^\d+\.\s*', '', stripped)
        blocks.append({
            "object": "block",
            "type": "callout",
            "callout": {
                "rich_text": parse_inline(text),
                "icon": {"type": "emoji", "emoji": "💡"}
            }
        })
        i += 1
        continue

    # Numbered list: 1. text
    if re.match(r'^\d+\.\s', stripped):
        text = re.sub(r'^\d+\.\s*', '', stripped)
        blocks.append(make_block("numbered_list_item", parse_inline(text)))
        i += 1
        continue

    # Bullet list: - text
    if stripped.startswith('- '):
        text = stripped[2:]
        blocks.append(make_block("bulleted_list_item", parse_inline(text)))
        i += 1
        continue

    # Blockquote: > text
    if stripped.startswith('> '):
        quote_text = stripped[2:].strip()
        blocks.append(make_block("quote", parse_inline(quote_text)))
        i += 1
        continue

    # Bold label: **Label:** value
    m = re.match(r'^\*\*(.*?):\*\*\s*(.*)', stripped)
    if m:
        label, value = m.groups()
        rt = [{"type": "text", "text": {"content": f"{label}: "}, "annotations": {"bold": True}}]
        if value:
            rt.extend(parse_inline(value))
        blocks.append(make_block("paragraph", rt))
        i += 1
        continue

    # Italic/timestamp lines
    if stripped.startswith('*') and stripped.endswith('*') and not stripped.startswith('**'):
        blocks.append({
            "object": "block",
            "type": "paragraph",
            "paragraph": {
                "rich_text": [{"type": "text", "text": {"content": stripped.strip('*')}, "annotations": {"italic": True, "color": "gray"}}]
            }
        })
        i += 1
        continue

    # Regular paragraph with inline formatting
    if stripped:
        blocks.append(make_block("paragraph", parse_inline(stripped)))

    i += 1


# --- Send to Notion API ---

# Create page with first 100 blocks
page_data = {
    "parent": {"page_id": parent_page_id},
    "icon": {"type": "emoji", "emoji": "🔍"},
    "properties": {
        "title": {
            "title": [{"type": "text", "text": {"content": page_title}}]
        }
    },
    "children": blocks[:100]
}

data = json.dumps(page_data).encode('utf-8')
req = urllib.request.Request("https://api.notion.com/v1/pages", data=data, headers=HEADERS, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        page_id = result.get('id', '')
        page_url = result.get('url', '')
        print(f"PAGE_CREATED:{page_url}")
except urllib.error.HTTPError as e:
    error_body = e.read().decode('utf-8')
    print(f"ERROR:{e.code}:{error_body}", file=sys.stderr)
    sys.exit(1)

# Append remaining blocks in batches of 100
remaining = blocks[100:]
batch_num = 1
while remaining:
    batch = remaining[:100]
    remaining = remaining[100:]

    append_data = {"children": batch}
    data = json.dumps(append_data).encode('utf-8')
    url = f"https://api.notion.com/v1/blocks/{page_id}/children"
    req = urllib.request.Request(url, data=data, headers=HEADERS, method='PATCH')

    try:
        with urllib.request.urlopen(req) as response:
            response.read()
            print(f"BATCH_{batch_num}:appended {len(batch)} blocks")
            batch_num += 1
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        print(f"ERROR:batch_{batch_num}:{e.code}:{error_body}", file=sys.stderr)
        sys.exit(1)

total = len(blocks)
print(f"TOTAL_BLOCKS:{total}")
PYTHON

RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ 완료!                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📂 위치: Notion → DesignHelp Research"
    echo ""
    echo "✅ 모든 작업이 자동으로 완료되었습니다!"
    echo ""
    echo "✓ 클릭 가능한 하이퍼링크"
    echo "✓ 텍스트 포맷팅 (굵기, 이탤릭, 코드)"
    echo "✓ 불릿/번호 리스트"
    echo "✓ 섹션 구분 (구분선)"
    echo "✓ 핵심 인사이트 콜아웃"
    echo "✓ 이미지 첨부 (Visual Examples)"
    echo "✓ 페이지 이모지 아이콘 (🔍)"
    echo ""
else
    echo -e "${RED}❌ Notion 저장 실패${NC}"
    echo ""
    echo "확인 사항:"
    echo "1. Notion Integration이 페이지에 연결(Connect)되어 있는지 확인"
    echo "2. .notion_credentials의 API 키가 올바른지 확인"
    echo "3. .notion_credentials의 페이지 ID가 올바른지 확인"
fi
