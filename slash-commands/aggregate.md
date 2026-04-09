# Aggregate Research Outputs

Combine individual research outputs into a single cohesive document.

## Steps

1. Read all files in `outputs/individual/` in chronological order.
2. Read the research brief from `context/from-human/research-brief.md`.
3. Create a combined document at `outputs/aggregated/markdown/YYYY-MM-DD-research-report.md` with:
   - **Title page**: Research topic, date range, number of iterations
   - **Executive summary**: 3-5 paragraph overview of all findings
   - **Methodology**: How the research was conducted (iterative prompting, sources consulted)
   - **Findings**: Organised thematically (not chronologically by prompt run)
   - **Analysis**: Synthesis, patterns, implications
   - **Open questions**: What remains unanswered
   - **References**: Consolidated source list from all individual outputs
4. If `pandoc` is available, also generate a PDF to `outputs/aggregated/pdf/`.
5. Report the aggregation summary.
