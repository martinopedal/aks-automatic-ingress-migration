# Sage history

Activity log for Sage (Research and Runbook Author).

## 2026-04-22: Presentation deck creation

**Task:** Build self-contained HTML presentation for AKS Automatic ingress-nginx → AGC migration story.

**Context:**
- User requested reveal.js presentation from CDN (no build step).
- 5 sections, ~30 slides: timelines, what changes, ALZ Corp placement, runbook, quickstart.
- Must follow project style: no em dashes, citation rigor, concise prose.

**Files created:**
- `presentation/index.html`: 29,220 characters, reveal.js 5.x, black theme, speaker notes on every slide.
- `presentation/README.md`: 3,148 characters, viewing instructions (file system, HTTP server, print to PDF).

**Learnings:**
1. **Deck structure:** Used nested `<section>` elements for 5 top-level sections with subsections. Each section is a vertical stack navigable with up/down arrows.
2. **Speaker notes:** Used `<aside class="notes">` on every slide. Notes are accessible via `S` key in browser (opens popup). Notes are not included in PDF export (reveal.js limitation).
3. **Citations:** Embedded in `<p class="citation">` elements with links to MS Docs and GitHub. All retirement dates (March 2026, November 2026) and preview status (ADR-003, verified April 22, 2026) are cited.
4. **ALZ Corp context:** Emphasized hub-spoke topology, Azure Firewall egress, private cluster API, and AGC internal frontend. Architecture slide shows traffic flow: Internet → Front Door → Firewall → AGC → AKS pods.
5. **Preview reality check:** Dedicated slide in Section 3 for AGC private cluster preview status. Highlighted as BLOCKER in runbook Phase 00.
6. **Annotation gaps:** Covered Lua snippets, custom auth, rate limiting, and canary deployments in Section 2 "Known gaps" slide. Aligned with ingress2gateway v1.0 GA translation scope.
7. **Tool usage:** Encountered repeated tool call error (missing `file_text` parameter) before successful creation. Must always include complete file content in `create` tool calls.

**Validation:**
- Deck renders correctly in Chrome and Firefox (tested via file:// and http-server).
- Speaker notes open in popup window with `S` key.
- PDF export via `?print-pdf` query string produces clean output (background graphics enabled).
- All citations load (no broken links).

**Next steps:**
- Decision record created: `.squad/decisions/inbox/sage-presentation-deck.md`.
- No ADR required (presentation is documentation, not architecture).
- Future updates: Edit `presentation/index.html` directly. No build step.

**Cross-references:**
- ADR-001: Repo positioning (orchestration layer, not translator) → reflected in Section 1 "What this repo provides" slide.
- ADR-002: Bicep-Terraform parity → reflected in Section 3 "IaC parity" slide.
- ADR-003: AGC private cluster preview gate → reflected in Section 3 "Preview reality check" slide and Section 4 Phase 00 slide.
- `.squad/agents/sage/charter.md`: Style guidance (cite URLs, skeptical of marketing) → followed in all speaker notes.

## Learnings

### 2026-05-12: Project voice profile established

**Scope:** Pending voice rewrite covers 18 docs + 3 READMEs (full list in `.squad/decisions.md`).

**Key reference:** `.squad/skills/voice-profile/SKILL.md` — read before any prose work.

**Rules:** 
- Strip em dashes, AI phrases, and all emojis except `✓` ✗.
- Banned-phrase list applies (leveraging, seamless, unlock, journey, robust, comprehensive, cutting-edge, deep dive, furthermore, moreover, additionally, at the end of the day, elevate, empower, accelerate, streamline, optimize, enterprise-grade, production-ready, future-proof, AI-powered, digital transformation, etc.).
- Break uniform paragraph rhythm if four equal-length paragraphs in a row.
- Cut bold-heading-colon filler, tricolon openers, forced analogies, question-then-self-answer rhythm.
- Preserve all technical content, citations, command examples. This is voice rewrite, not content rewrite.

**Quality gate before merge:** (1) Opening sentence stops scroll, (2) at least one specific technical detail, (3) concrete CTA, (4) no em dashes/banned phrases, (5) no AI structural patterns, (6) all date/default claims link to primary sources.

**Next session:** Sage sweeps listed files, applies voice profile, commits with `chore(docs):` prefix.
