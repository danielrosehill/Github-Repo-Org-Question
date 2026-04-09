# Run Next Prompt

Execute the next research prompt in the workflow.

## Steps

1. Check `prompts/queue/` for any queued prompts. If found, take the first one (alphabetically).
2. If no queued prompts, check `prompts/run/initial/` for unexecuted initial prompts.
3. If no initial prompts remain, check `prompts/run/subsequent/` for follow-up prompts.
4. Before running, read all files in `context/from-human/`, `context/from-history/`, and `context/from-internet/` to build full context.
5. Execute the prompt: conduct the research, use web search and reasoning as needed.
6. Save output to `outputs/individual/YYYY-MM-DD-{descriptive-slug}.md` with:
   - `## Key Findings` as the opening section
   - `## Sources` as the closing section
   - Clear markdown structure throughout
7. If the prompt came from `prompts/queue/`, move it to `prompts/run/initial/` or `prompts/run/subsequent/` as appropriate.
8. Report what was run and a brief summary of findings.
