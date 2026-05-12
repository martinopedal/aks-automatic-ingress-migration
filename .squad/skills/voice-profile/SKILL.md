---
name: voice-profile
confidence: medium
source: Anonymized from news-fetcher/src/drafts/voice_profile.md (2026-05 revision)
applies_to: All prose in this repo. Docs, ADRs, runbook, READMEs, presentation copy, PR descriptions, commit messages.
---

# Voice Profile (Project Standard)

This is the project's writing voice. Read it before producing or rewriting any prose. Use it for docs, runbook phases, ADRs, READMEs, presentation copy, and any other long-form text.

The rules below are derived from the maintainer's actual voice and adapted to be useful for any contributor. Apply them whether you are a human or an agent.

## How to write

Open directly. State the position or observation in the first sentence. No filler. No "In today's world", no "As we all know", no "I'm excited to share". Get to the point.

State conclusions before reasoning. Give the answer first, then explain why. The reader knows where you stand immediately.

Use concrete examples. Name specific tools (ALZ Terraform module, AGC, Karpenter, Application Gateway for Containers, ingress2gateway). Do not talk in abstractions when you can point to something real.

Be pragmatic over theoretical. What works in production beats what looks good in a diagram.

Be constructive. Share what works and what to watch out for, but do not sound cynical or artificially critical. The tone is "experienced engineer helping you succeed", not "outsider pointing out flaws". When you mention a problem, pair it with a practical mitigation.

Be accountable. When something is broken, say so plainly. No deflection, no hedging passive voice.

End on a statement more often than a question. Do not force a discussion invite.

## What to never do

- Em dashes or en dashes. Use commas, periods, or "and" instead.
- Emojis. The only allowed emojis in docs are ✓ (checkmark) and ✗ (cross), used sparingly as status markers in tables or checklists.
- AI-sounding phrases: "leveraging", "leverage", "driving", "unlocking", "in today's landscape", "game-changer", "deep dive into", "at the end of the day", "it goes without saying", "journey", "comprehensive", "robust", "cutting-edge", "seamless", "elevate", "empower", "accelerate", "streamline", "optimize", "enterprise-grade", "production-ready", "future-proof", "AI-powered", "digital transformation", "modernizing", "now more than ever", "across industries".
- AI transition words: "furthermore", "moreover", "additionally", "on the other hand", "in conclusion", "to sum up", "in fact", "the reality is", "the truth is", "it's worth noting", "one thing is clear", "here's the thing", "the takeaway".
- AI sign-offs: "feel free to connect", "if you found this helpful", "happy to chat", "agree?", "thoughts?".
- Arrow bullets or other unicode bullet ornaments. Use plain `-` in markdown lists.
- Opening with "I'm excited to..." or "Thrilled to...".
- The word "journey" to describe progression of any kind.
- Corporate marketing copy disguised as technical writing.

## Anti-AI structural rules

These are the structural tells that survive even when the phrase blacklist is clean. Reject any draft that hits any of them.

- **No question-then-self-answer paragraph rhythm.** "But what does this actually mean? Let's dive in." is the canonical AI rhythm. If you ask a question, leave it open or have the next paragraph stake a position. Never auto-answer.
- **No forced analogies that compare technical work to sports, cooking, or marathons.** "Much like running a marathon, deploying a Landing Zone takes pacing." Cut it cold.
- **No "Bold heading: explanation" paragraph pattern** (`**Speed**: faster pipelines. **Scale**: more nodes. **Stability**: fewer alerts.`). The visual rhythm collapses to a list of fragments and the model loves it because it's safe filler.
- **No tricolon openers** ("Faster. Cheaper. Smarter."). Three-word punchlines at the top are filler. Open with a specific moment instead.
- **No "3 lessons" arc from thin material.** If you only have one real point, write one real point.
- **No symmetrical sentence pairs** ("X is changing. Y is changing. Z is changing.").
- **No moral-of-the-story endings** ("The future belongs to those who adapt").
- **No false-contrast frames** ("It's not about X, it's about Y").
- **No over-signposted structure** ("Here's the thing... The reason is simple...").

## Structural variation

Vary structure between sections and between documents. The reader should not be able to predict the shape of the next paragraph.

- Do NOT use the same paragraph length throughout.
- Do NOT follow a predictable pattern (intro, three points, conclusion).
- Mix one long detailed paragraph, then a short punchy line, then a medium one.
- Sometimes skip the intro entirely and start with the point.
- Sometimes end abruptly after the strongest statement instead of wrapping up.

## Technical depth

Posts and docs should reflect hands-on expertise, not surface-level commentary. When mentioning a technology, include something specific that shows the author uses it daily.

Good: "Azure Policy exemptions support time-bound, auditable exemptions natively. Most teams have never configured one."

Bad: "Governance is important for cloud security."

Good: "Karpenter node provisioning needs careful subnet sizing. The defaults assume more IP space than most ALZ Corp spoke VNets provide."

Bad: "Make sure to plan your Kubernetes networking properly."

## Formatting rules for docs

- No emojis except ✓ ✗ as status markers.
- No em dashes or en dashes.
- No bullet point unicode ornaments.
- Headings sentence-case where the rendering allows it. Avoid title-case for body headings.
- Code blocks have language tags so renderers can highlight them.
- Citations to external docs go inline near the claim, not parked in a "References" section that nobody scrolls to. A trailing "References" section is fine if the body also names the source where it matters.
- Every factual claim about retirement dates, default behaviour, version-specific behaviour, region lists, supported feature flags, or SLAs links inline (not in a trailing References section) to a primary source: learn.microsoft.com URL or upstream GitHub release page. Lists copied from a source must match the source exactly. If a claim cannot be cited from public material, do not make it.

## Norwegian rules (when applicable)

This repo is English-only by default. If a Norwegian section is added in future, the same anti-AI rules apply. Use proper æ, ø, å. Do not translate technical product names. Avoid Norwegian AI tells like "det er viktig å merke seg", "for å oppsummere", "videre er det verdt å nevne", "dette sikrer", "i denne sammenhengen".

## Quality check before merging any prose

Before declaring a doc done:

1. Does the first sentence stop the scroll? Would a working engineer read the next sentence?
2. Is there at least one specific technical detail that proves hands-on experience? A version, a default, a CLI flag, a subnet size.
3. If there is a CTA or "next step", is it concrete? "Run X" or "open issue Y" beats "consider exploring".
4. Free of em dashes, AI phrases, and emojis other than ✓ ✗?
5. No question-then-answer rhythm, no forced analogies, no bold-heading-list filler?
6. Every claim about a date or default behaviour links to a primary source?

If any of these fails, send it back.

## Citation hygiene examples

### ✓ Good citation (inline, verifiable)

> AGC is GA and supports 23 regions, per [Application Gateway for Containers overview](https://learn.microsoft.com/azure/application-gateway/for-containers/overview) (accessed 2026-05-13): Australia East, Brazil South, Canada Central, Central India, Central US, East Asia, East US, East US 2, France Central, Germany West Central, Korea Central, North Central US, North Europe, Norway East, South Central US, Southeast Asia, Switzerland North, UAE North, UK South, West US, West US 2, West US 3, West Europe.

Why this works:
- Citation is inline, immediately after the claim.
- Region list is exact and complete, copied from source.
- Access date provided.
- Reader can verify the claim by following the link.

### ✗ Bad citation (invented list, wrong source)

> AGC is GA and supports major Azure regions. Most customers deploy in West Europe, North Europe, or East US. See [AKS overview](https://learn.microsoft.com/azure/aks/intro-kubernetes) for details.

Why this fails:
- "Major Azure regions" is vague. No specific list.
- "Most customers deploy in..." is an invented claim with no source.
- AKS overview page does not list AGC regions. Wrong source cited.
- No access date.
- Reader cannot verify the claim.

Rule: If you copy a list (regions, feature flags, versions, supported configurations) from a Microsoft Learn page, copy it exactly and cite the specific page inline. If you infer or summarize, you are inventing, and the citation is false.

## What to do instead

- Start with a concrete observation or the actual technical situation, never a topic introduction.
- Every section should include at least one of: a number, an incident, a tradeoff, a constraint, a named decision.
- If an abstract noun appears, pair it with a concrete mechanism in the same sentence.
- Prefer operational detail over motivational framing.
- End on an observation or conclusion, not a CTA or engagement bait.
- Sentence fragments are fine for emphasis. Roughness beats polish.
- Name specific tools (AKS, Terraform, Bicep, AGC, Helm), not categories ("container orchestration", "managed Kubernetes").
- Admit uncertainty when real ("AGC private cluster GA is still unconfirmed").
- One sharp point beats three balanced points.
- Use action verbs: cut, fixed, removed, shipped, delayed, tested, blocked. Not elevate, empower, accelerate, streamline.

## Source

The full source profile lives in the maintainer's `news-fetcher/src/drafts/voice_profile.md` and the global `~/.copilot/skills/writer/SKILL.md`. This file is the anonymized, repo-portable subset. If the source profile changes, this file should be updated to match.
