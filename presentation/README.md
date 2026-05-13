# AKS Automatic ingress-nginx → AGC Migration Presentation

Self-contained reveal.js presentation deck for the migration story.

## Viewing

### Option 1: File system (simplest)

1. Open `index.html` in a modern browser (Chrome, Edge, Firefox, Safari).
2. Navigate slides with arrow keys or click the arrows in the bottom right.
3. Press `S` to open speaker notes in a separate window.

**Note:** Some browsers restrict file:// JavaScript. If speaker notes don't open, use Option 2.

### Option 2: Local HTTP server

```bash
cd presentation
python -m http.server 8000
# Or with Python 2:
python -m SimpleHTTPServer 8000
# Or with Node.js:
npx http-server -p 8000
```

Then open `http://localhost:8000` in your browser.

Press `S` to open speaker notes.

## Printing to PDF

1. Open the presentation in Chrome or Edge.
2. Append `?print-pdf` to the URL:
   - File system: `file:///C:/git/aks-automatic-ingress-migration/presentation/index.html?print-pdf`
   - HTTP server: `http://localhost:8000?print-pdf`
3. Open the browser print dialog (Ctrl+P or Cmd+P).
4. Set destination to "Save as PDF".
5. Expand "More settings" and enable "Background graphics".
6. Save.

The PDF will include all slides. Speaker notes are not included in PDF output (reveal.js limitation). To capture speaker notes, export them separately or view the HTML source.

## Structure

5 sections, ~30 slides:

1. **The clock is ticking** (5 slides): Timelines, why now, migration target, repo positioning.
2. **What changes** (7 slides): Mental model shift, Ingress vs Gateway API, annotation translation, known gaps, TLS, readiness checklist.
3. **Where AGC lives in ALZ Corp** (7 slides): ALZ shape, AGC placement, architecture diagram, Workload Identity, preview reality check, IaC parity.
4. **The runbook** (7 slides): 10-phase timeline, Phase 00 (prerequisites), Phases 02-03 (network and identity), Phase 04 (deploy AGC), Phases 05-06 (translate and test), Phase 09 (decommission).
5. **Try it** (4 slides): Quickstart, contribute, closing.

Every slide has speaker notes accessible via the `S` key.

## Dependencies

All dependencies are loaded from CDN:

- **reveal.js 5.x**: `https://cdn.jsdelivr.net/npm/reveal.js@5/`
- **reveal.js theme**: black (dark, for terminal/Azure feel)
- **reveal.js plugins**: Notes (speaker notes)

No build step required. No npm install. No local files except `index.html` and this `README.md`.

## Maintenance

To update the deck:

1. Edit `index.html` directly (single HTML file).
2. Test by opening in browser (use Option 2 if speaker notes break).
3. Commit and push.

Citations are inline with `<p class="citation">` elements. All retirement dates and technical claims link to MS Docs or upstream GitHub issues.

## Style

No em dashes. Use commas or periods. Every claim about retirement dates, default behavior, or preview status links to MS Learn or upstream GitHub. Speaker notes are direct prose, not marketing copy.

Follows project conventions in `.github/copilot-instructions.md`.
