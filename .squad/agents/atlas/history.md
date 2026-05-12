# Atlas history

Activity log for Atlas (Kubernetes manifests, Gateway API translation, Helm).

## Learnings

### 2026-05-12: Presentation deck redesign deferred

**Task:** Redesign reveal.js deck (`presentation/index.html`) per pptx skill design principles.

**Target file:** `presentation/index.html` (single-file reveal.js, 29 KB, CDN-loaded, no build step).

**Design requirements:**
1. Read `.squad/skills/voice-profile/SKILL.md` first, then global `pptx` skill at `~/.copilot/skills/pptx/SKILL.md` (Design Ideas section, color palettes, typography table), and `C:\git\dnb-foundry-agent-demo\.squad\skills\demo-deck-structure\SKILL.md` for story arc.
2. Pick palette appropriate to topic. AKS migration suggests `Ocean Gradient` (`065A82` / `1C7293` / `21295C`) or `Charcoal Minimal` (`36454F` / `F2F2F2` / `212121`). Pick one. Commit to it.
3. Dominance: one color 60-70% visual weight, one or two supporting tones, one accent.
4. Sandwich structure: dark title/conclusion slides, light content slides. Or go dark throughout for premium feel.
5. Visual motif: pick one and repeat on every slide (thin colored corner accent, icon-in-circle for section markers, left-edge timeline rail). Consistency across all slides.
6. Typography pairing: header/body pair from pptx skill. Workable pairs: `Georgia` header + `Calibri` body, `Cambria` + `Calibri`, `Arial Black` + `Arial`, or system stack with weight contrast.
7. Every slide gets at least one visual element. No text-only slides. Icons, callout boxes, side-by-side comparisons, large stat callouts (60-72pt), timelines, process flows. Use unicode glyphs sparingly (no emojis, but boxes/arrows for flow diagrams acceptable).
8. Layout variation across slides: two-column, icon+text rows, 2x2 grid, half-bleed image with overlay. Do not repeat same layout twice in a row.
9. **NEVER add accent line under titles.** This is a known AI-tell per pptx skill. Use whitespace or background color instead.
10. Apply voice rules to slide copy. Strip em dashes, AI phrases. Open slides with the actual point, not topic introduction.
11. Keep single-file reveal.js with CDN imports. No build step. Speaker notes in `<aside class="notes">` stay.
12. Story arc: keep all current content (10-phase runbook, AGC mental model, retirement timeline, ALZ Corp posture). Polish visual treatment.

**Slide copy tone:**
- No tricolons in titles.
- No bold-heading-list filler.
- Slide titles sentence-case, not Title Case.
- Cut every "Why X matters" slide that does not answer with specific number, incident, or constraint.
- Speaker notes carry depth. Slides carry punch.

**Next session:** Atlas renders deck locally, inspects at least three slides visually before declaring done. Coordinate with Sage on shared docs/presentation scope.
