---
description: Resume the ongoing repo-org research — pick up where we left off, or evaluate a specific tool against SCOPE.md
---

# /resume

This is an **ongoing research notebook**, not a one-shot project. Every invocation picks up from the accumulated state.

## Step 1 — Load context

Read, in order:

1. `SCOPE.md` — the live spec (pain points, hard requirements, settled architecture, tools already evaluated)
2. The most recent file in `outputs/final/` — the latest synthesis
3. The most recent 3–5 files in `outputs/individual/` (sorted by date in filename) — recent iterations
4. Any files in `context/from-history/` — compacted prior rounds
5. `prompts/queue/` and `prompts/drafting/` — anything queued or in-progress

Do not re-read every historical output unless the user asks for it. The synthesis + SCOPE are enough for context.

## Step 2 — Branch on arguments

### If invoked as `/resume` (no arguments)

Report a short status (≤10 lines):

- Last iteration date and topic
- Current architectural conclusion (one sentence)
- Any open questions from `SCOPE.md`
- Any queued prompts

Then ask the user what they want to do next. Offer concrete options:

- Continue an open question from `SCOPE.md`
- Add a new pain point or angle to investigate
- Evaluate a new tool (`/resume evaluate <tool>`)
- Update `SCOPE.md` with new learnings
- Generate a fresh synthesis / aggregate / PDF

### If invoked as `/resume evaluate <tool-name-or-url>`

Evaluate the named tool against `SCOPE.md`. Produce a scorecard covering:

1. **Identity model** — keys on remote URL, or on path? (Disqualifier if path-only.)
2. **Data-loss safety** — refuse-on-dirty by default? (Disqualifier if not.)
3. **Inventory scope** — uncloned remote repos, local clones, or both?
4. **Navigation** — fuzzy search? frecency? per-result action hotkeys?
5. **Multi-machine replication** — git-committable manifest/config?
6. **Bulk ops covered** — which capabilities from the SCOPE's "Desired capabilities" section does it hit?
7. **Composability** — does it fit alongside the existing five-layer stack, or does it try to own the whole problem?

Use web search if the tool is unfamiliar. Be honest about gaps and disqualifiers. Conclude with one of:

- **Recommended for use** — fits a layer in the stack, no disqualifiers
- **Worth knowing, not primary** — partial fit, note what it's useful for
- **Ruled out** — state the specific disqualifier

Save the evaluation to `outputs/individual/YYYY-MM-DD-eval-<tool-slug>.md` following the standard output format. Update `SCOPE.md`'s "Tools evaluated" section with the verdict.

### If invoked as `/resume <free-text question>`

Treat the free text as a new research question. Draft a prompt file in `prompts/run/subsequent/YYYY-MM-DD-<slug>.md` citing `SCOPE.md` and the latest synthesis as context, then execute it per the standard research workflow in `CLAUDE.md`, saving the output to `outputs/individual/`.

## Step 3 — Always update SCOPE.md if learnings shifted

If the iteration surfaced a new pain point, requirement, disqualifier, or tool verdict, update `SCOPE.md` in the same session. SCOPE is a living document — keeping it current is the whole point of this workflow. Bump the "Last updated" date.

## Step 4 — Report

End the session with a short summary:

- What was added to the notebook
- Any SCOPE.md edits
- Suggested next iteration (if any)

Do not regenerate the PDF unless asked — that's a separate explicit step.
