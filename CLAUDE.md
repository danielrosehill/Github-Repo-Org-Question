# Research Workspace — Claude Code Instructions

## What This Is

This is a structured research workspace powered by Claude Code. It uses a folder-based pattern for iterative AI research: context goes in, prompts get run, outputs get saved, and previous outputs feed back as context for deeper investigation.

## Directory Map

| Directory | Purpose |
|-----------|---------|
| `context/from-human/` | Background info, notes, source material you provide |
| `context/from-history/` | Compacted summaries from previous research iterations |
| `context/from-internet/` | Web sources, articles, reference material |
| `prompts/drafting/` | Prompts under development |
| `prompts/queue/` | Prompts ready to run (in order) |
| `prompts/run/initial/` | First-pass research prompts |
| `prompts/run/subsequent/` | Follow-up prompts that build on earlier outputs |
| `outputs/individual/` | Raw output from each prompt run |
| `outputs/aggregated/markdown/` | Combined multi-output documents |
| `outputs/aggregated/pdf/` | PDF exports of aggregated research |
| `outputs/final/` | Polished deliverables |
| `notes/` | Working notes, observations, methodology |

## Research Workflow

### Prompts given directly in chat

If the user supplies a research prompt directly in the chat (rather than placing a file in `prompts/queue/`), first persist it before acting on it:

1. Save the prompt to `prompts/run/initial/YYYY-MM-DD-{slug}.md` (or `prompts/run/subsequent/` if it builds on prior outputs), using today's date. **Lightly clean the prompt** before saving — do not paste it verbatim. The goal is to capture the substance of the question(s), not every character the user typed.
2. Then process it following the normal "Running a prompt" workflow below.

### Light cleanup rules for persisted prompts

Always apply a brief editorial pass before saving:

- Fix obvious typos, mis-segmented words, and voice-typing / one-handed-typing artifacts (homophones, missing spaces, stray characters).
- Trim filler — "so", "basically", "I was thinking maybe", false starts, mid-sentence restarts, meta-commentary ("ignore the last bit, what I meant was...").
- Normalize punctuation and paragraph breaks for readability.
- Preserve the user's **intent, questions, structure, and emphasis**. Do not rewrite, reorder, or add new requirements.
- Keep it recognizable as the user's own phrasing — this is a light polish, not a rewrite.

This guarantees every piece of research in the repo has a corresponding, dated prompt file on disk — and the persisted record is readable rather than a literal transcript.

### Running a prompt

1. Read all files in `context/` to build background understanding
2. Read the prompt file from `prompts/run/` (initial or subsequent)
3. Conduct the research using available tools (web search, document analysis, reasoning)
4. Save the output to `outputs/individual/` with format: `YYYY-MM-DD-{slug}.md`
5. If the prompt file was in `prompts/queue/`, move it to the appropriate `prompts/run/` folder after execution

### Building on previous work

Before running any subsequent prompt, always read:
- All files in `context/from-history/` (compacted prior findings)
- All files in `context/from-human/` (operator-provided material)
- The most recent outputs in `outputs/individual/` if they're relevant

### Output formatting

- Use clear markdown with headers, bullet points, and tables where appropriate
- Include a `## Sources` section at the end of every research output
- Use `## Key Findings` as the opening section
- Date-stamp all outputs in the filename

### Compaction

When instructed to compact (or when context is getting large), summarize the current research state:
- Read all files in `outputs/individual/`
- Create a comprehensive summary in `context/from-history/` named `YYYY-MM-DD-compaction.md`
- The summary should preserve key findings, sources, open questions, and contradictions
- This becomes the foundation context for subsequent research iterations

### Aggregation

When instructed to aggregate:
- Combine relevant individual outputs into a single document in `outputs/aggregated/markdown/`
- Add a cover section with research topic, date range, and methodology summary
- Compile all sources into a unified references section
- Optionally generate PDF to `outputs/aggregated/pdf/`

## Behaviour Guidelines

- Be thorough and cite sources
- Flag uncertainty and contradictions explicitly
- Distinguish between established facts, emerging consensus, and speculation
- When web searching, try multiple queries and cross-reference
- Preserve the full reasoning chain in outputs — these are research documents, not chat responses
