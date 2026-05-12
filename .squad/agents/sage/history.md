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

### 2026-05-12: PRs shipped and spawn manifest closed

Voice sweep PR #49 merged. Deck redesign PR #50 merged. PR #51 logged learnings.

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

### 2026-05-12: Voice sweep executed (PR #49)

Branch `chore/docs-voice-sweep`, 16 files modified, opened as PR #49.

What the corpus actually looked like before the sweep, in order of frequency:

1. The dominant violation was H1 em dashes in runbook phase headings. Every single phase file (`00-prereq-agc-availability.md` through `09-rollback.md`, 10 files) used the pattern `# Phase NN — Title`. Replaced with `# Phase NN, title`. If a future contributor adds an `11-` or `12-` phase doc, they will almost certainly reach for the em dash by reflex. Worth a lint rule.

2. The second most prevalent pattern was bold-heading-colon tricolon filler at the END of READMEs, packaged as `## Style` or `## Design Philosophy`. Two of three module READMEs ended with this pattern (`scripts/migration/README.md`, `presentation/README.md`). The hello-world README was clean. The pattern reads as a sign-off ritual, like a corporate values poster nailed to the bottom of the doc. Both were rewritten as prose paragraphs that name concrete cmdlets, failure modes, and references.

3. Banned phrases were rare. Only two prose instances across 22 files (`leverage` in ADR-001, `accelerate` in ADR-003). All other matches for `accelerat` were inside the Microsoft product slug `landing-zone-accelerator` in URLs and link titles, which cannot be changed. The phrase list is doing more work than the count suggests, because authors self-censor against it once they know it exists.

4. Title-case headings were the slow-burn issue: `Alternatives Considered`, `Refresh Procedure`, `What Parity Means`. Eight headings flipped to sentence case across the three ADRs and the compatibility matrix.

5. Spelling drift (`Cost-optimised`, British) appeared once in a topology table in Phase 04. Worth a future pass with a configured spell list, but not urgent.

What did NOT need rewriting:

- Numbered ADR contract enumerations (e.g. ADR-002 `1. **Names.** Output keys match...`) read as semantic data, not decorative tricolon.
- The `→` arrow character in `Ingress → HTTPRoute` and similar is not a dash, not an emoji, and not a bullet ornament. Voice profile is silent on it. Left in place. Reconsider if it spreads.
- Words like `simplest`, `easy rollback`, `Smallest blast radius` in tables are pragmatic operational descriptors, not AI marketing tells.

Things to watch for in future sweeps:

- New phase docs reaching for em dashes in H1.
- New READMEs ending with a `## Style` or `## Philosophy` tricolon coda.
- Any spread of the `→` arrow into prose (currently only in titles and conversion arrows).
- Any new `**Bold**: filler.` patterns introduced by Atlas, Iris, or Sentinel in their own docs as the contributor base grows.

The corpus was in better shape than expected. Two phrase rewrites, one British spelling, eight heading flips, two README codas, and ten H1 em dashes. The voice profile is mostly preventing future drift, not cleaning up existing damage.
## 2026-05-12: Presentation deck redesign (pptx skill + voice profile)

**Task:** Redesign `presentation/index.html` to apply pptx skill design principles and the project voice profile. Same 30-slide structure, full visual rebuild. (PR #50)

**Design decisions:**
- **Palette: Charcoal Minimal** (`#1A1F24` bg, `#E8E6E3` text, `#FFB400` amber). Picked from the pptx skill table because the deck is a delivery-context piece (warning/deadline-driven). Amber as the sharp accent: numeric badges in the section chip, right-edge rule, callout ribbons, code-block left border, stat numbers. Dark throughout (no light/dark sandwich).
- **Typography:** Georgia (headers) + system sans (body). Tested the four pairings from the pptx skill and Georgia worked best with the charcoal palette because serif weight balances the dark surface; system sans keeps body legible at 26 px.
- **Motif (two parts that repeat on every slide):**
  1. Section chip top-left: amber numeric badge `01` + muted-grey section name. Injected post-render via `Reveal.on('ready', ...)` so I did not have to hand-type it 30 times.
  2. Thin amber rule (2 px, 0.4 opacity) on the right edge via `::after`. Quiet repeat element that signals deck ownership without stealing focus.
- **Layout variation:** hero, stat-row, 2x2 card grid, two-column (left-heavy and right-heavy variants), inline SVG diagrams (hub-spoke, traffic flow), phase timeline with circular dots, comparison tables, code blocks. Verified no two adjacent slides share a layout.
- **Section dividers** redesigned: huge serif numeral (`02`, `03`, `04`, `05`) plus title and lede. Replaces the original generic h1+h2 dividers.

**Voice profile applied to slide titles:**
- `Why now?` → `The planning window is 3 to 6 months.` (dropped question-then-answer)
- `Migration target` → `What you migrate to.`
- `PREVIEW reality check` → `Private cluster AGC is still preview.`
- `End game` → `Get off ingress-nginx before November 2026.` (cover hero)
- All titles sentence-case, declarative, no em dashes.

**Reveal.js learnings:**
1. **Chip injection via JS.** Outer `<section data-section="01 / Deadline">` carries the label, JS iterates `:scope > section` children and appends a `.chip` div. Cover slide opts out with `data-nochip`. Avoids polluting markup with 30 repeated chip blocks.
2. **Right-edge rule via `::after`.** Reveal.js gives every slide `position: relative` so absolute positioning on `::after` just works. No need to wrap content in extra containers.
3. **No accent line under titles.** The pptx skill explicitly flags this as an AI tell. Borders go on cards, code blocks, table headers, the section chip, and the right edge — never under h2/h3.
4. **Inline SVG over image assets.** Two diagrams (hub-spoke topology, traffic flow Internet → Front Door → Firewall → AGC → AKS) drawn directly in SVG. Keeps the deck a single self-contained file; no asset pipeline. Used the same charcoal palette and amber accent in stroke colours so diagrams match the slide design.
5. **HTML entities for status glyphs.** `&#10003;` and `&#10007;` for ✓/✗ in the comparison tables. Avoids emoji rendering inconsistencies and keeps the slide austere.
6. **Reveal config:** `width: 1280, height: 760, margin: 0.04, transition: 'fade', slideNumber: 'c/t', hash: true`. Fade is calmer than slide transitions for a technical deck. `c/t` slide number reads better than just `c`.

**Tool note:** First `create` attempt failed with "already exists" after `Remove-Item` — the file got restored between calls (likely by an editor watcher or a transient race). Fix: `Remove-Item -Force` immediately followed by `create` in the next response. Pattern to remember when redoing files in this repo.

**Branch hygiene:** Initial commit landed on `chore/docs-voice-sweep` (the prior session's branch from PR #49). Moved it cleanly to a dedicated `chore/presentation-redesign` branch via `git rebase --onto origin/main chore/docs-voice-sweep chore/presentation-redesign` so PR #50 ships as a single commit on top of `main`, independent of #49.

**Final stats:** 1171 lines, 49,449 bytes, 35 `<section>` open/close pairs balanced, 107 `<div>` open/close pairs balanced, 30 inner slides across 5 outer sections.
