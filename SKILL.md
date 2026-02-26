---
name: design-research
description: 디자인 리서치를 수행하고 Notion 보고서로 자동 작성. Use when the user asks for design research, UX research, UI analysis, competitive analysis, or trend research.
disable-model-invocation: true
user-invocable: true
argument-hint: [리서치 주제]
allowed-tools: Read, Grep, Glob, Bash, WebSearch, WebFetch
---

# 디자인 리서치 + Notion 보고서 자동화

리서치 주제: **$ARGUMENTS**

아래 전체 과정을 자동으로 순서대로 수행한다.

---

## Phase 1: [사전] Chrome 탭 저장 및 종료

Playwright MCP는 Chrome 프로세스가 없어야 동작하므로 반드시 수행한다.

1. AppleScript로 현재 열려 있는 **모든 윈도우의 모든 탭 URL**을 수집하여 `/tmp/chrome_tabs_backup.txt`에 저장
   ```bash
   osascript -e 'tell application "Google Chrome" to set tabURLs to "" & linefeed
   tell application "Google Chrome"
     repeat with w in windows
       repeat with t in tabs of w
         set tabURLs to tabURLs & URL of t & linefeed
       end repeat
     end repeat
   end tell
   return tabURLs' > /tmp/chrome_tabs_backup.txt
   ```
2. Chrome 정상 종료
   ```bash
   osascript -e 'tell application "Google Chrome" to quit'
   ```
3. 2초 대기 후 잔여 프로세스 종료
   ```bash
   sleep 2 && pkill -f "Google Chrome"
   ```

---

## Phase 2: [본작업] 웹 리서치 수행

1. **WebSearch**로 주제 관련 정보 수집
2. **WebFetch**로 주요 페이지 상세 내용 추출
3. **Playwright MCP**로 시각적 자료(스크린샷, UI 패턴) 수집
4. 수집한 이미지 URL을 Python으로 일괄 HTTP HEAD 검증

---

## Phase 3: 이미지 수집 및 검증 규칙

### 지원 포맷
- PNG, JPG, GIF, WEBP만 사용 가능
- **AVIF 포맷 사용 금지** (Notion 미지원)

### 이미지 선별 기준 (엄격 적용)
- 보고서 본문 내용과 **직접적으로 관련된 이미지만** 사용
- 관련성 판단: 해당 이미지가 본문에서 설명하는 특정 앱, 기능, UI 패턴, 개념을 직접 보여주는지 여부
- 적합한 이미지가 없는 섹션은 **텍스트만으로 작성** (무관한 이미지 억지 삽입 금지)
- 공식 사이트/블로그에서 직접 수집

### CDN 핫링크 주의사항
- **안전한 CDN**: `storage.googleapis.com`, `blog-static.userpilot.com`, `sendbird.imgix.net`, `www.datocms-assets.com`, `api.outrank.so`, `files.smashing.media`, `images.storychief.com`
- **위험한 CDN**: `cdn.prod.website-files.com` (Webflow) — 사이트별로 핫링크 차단 여부 다름, 반드시 개별 검증

### HTTP 검증 (보고서 작성 전 필수)
모든 이미지 URL을 Python으로 일괄 검증:
```python
import urllib.request
for url in image_urls:
    req = urllib.request.Request(url, method='HEAD')
    resp = urllib.request.urlopen(req)
    # status 200 + content-type이 image/* 인지 확인
```

---

## Phase 4: Markdown 보고서 작성

### 보고서 구조
1. **제목** (H1) — 리서치 주제를 명확히 → Notion 페이지 타이틀이 됨
2. **핵심 요약** — 3~5줄 이내로 주요 발견 요약
3. **배경/목적** — 왜 이 리서치를 했는지
4. **조사 내용** — 상세 분석 (섹션별 구분, 불릿 포인트/표/다이어그램 활용)
5. **Visual Examples** — 관련성 높은 이미지만 `![캡션](url)` 문법으로 삽입 + 설명
6. **시사점 / 결론** — 핵심 인사이트와 다음 액션
7. **출처** — 하이퍼링크 형식

### 작성 규칙
- 가독성 우선: 긴 텍스트보다 불릿 포인트, 표, 다이어그램 활용
- Visual example에는 간단한 캡션/설명 추가
- 테이블은 Markdown 표 문법 사용 (`| col1 | col2 |` + `|---|---|`)
- 이미지는 `![캡션](url)` 문법 → Notion image block으로 변환됨

### 출처 작성 규칙 (필수)
```markdown
### 출처
- [출처 이름](URL)
- [출처 이름](URL)
```
- 반드시 클릭 가능한 하이퍼링크로 작성
- 이탤릭(`*...*`)으로 **절대** 감싸지 않음 (Notion 변환 시 링크 파싱 깨짐)
- 각 출처는 개별 불릿 항목으로 분리

---

## Phase 5: Notion 업로드

보고서 파일을 `/Users/ethanpark/AI-vibe/DesignResearch/` 디렉토리에 저장한 후:

```bash
cd /Users/ethanpark/AI-vibe/DesignResearch && ./save_to_notion.sh <report_filename.md>
```

- Credentials: `/Users/ethanpark/AI-vibe/DesignResearch/.notion_credentials`
- `save_to_notion.sh`가 Markdown 테이블을 Notion table block으로 자동 변환

---

## Phase 6: [사후] Chrome 탭 복원

1. 저장해둔 탭 파일에서 URL을 읽어 Chrome 복원
   ```bash
   first_url=$(head -1 /tmp/chrome_tabs_backup.txt)
   open -a "Google Chrome" "$first_url"
   sleep 2
   tail -n +2 /tmp/chrome_tabs_backup.txt | while read url; do
     [ -n "$url" ] && osascript -e "tell application \"Google Chrome\" to open location \"$url\""
   done
   ```
2. 백업 파일 삭제
   ```bash
   rm -f /tmp/chrome_tabs_backup.txt
   ```
