[![Claude Code Projects Index](https://img.shields.io/badge/Claude%20Code-Projects%20Index-blue?style=flat-square&logo=github)](https://github.com/danielrosehill/Claude-Code-Repos-Index)

# Github-Repo-Org-Question

An **ongoing research notebook** investigating how to manage a large personal GitHub repo fleet — organisation, navigation, multi-machine sync, bulk lifecycle ops, and launcher UX. Not a one-shot research project: this is a living document that gets picked up whenever a new angle, tool, or pain point surfaces.

Built on Daniel's Claude Research Workspace template — iterative AI-assisted research with Claude Code as the execution engine.

## What this notebook is trying to answer

> *"How do I manage hundreds of personal GitHub repos across multiple machines without wasting time on navigation, losing work to sync accidents, or fighting the filesystem every time folders get reorganised?"*

Full pain-point list and learned requirements live in [`SCOPE.md`](SCOPE.md). Read that first if you're resuming work.

## Current state

- **Architecture settled** (09/04/26): five-layer stack keyed on `git remote get-url origin`, not filesystem paths. Synthesis in [`outputs/final/2026-04-09-repo-management-synthesis.md`](outputs/final/2026-04-09-repo-management-synthesis.md).
- **Implementation brief** ready for a downstream agent: [`outputs/final/2026-04-09-implementation-agent-prompt.md`](outputs/final/2026-04-09-implementation-agent-prompt.md).
- **Printable PDF** of the synthesis: [`outputs/aggregated/pdf/synthesis.pdf`](outputs/aggregated/pdf/synthesis.pdf).

## Resuming work

Open the repo in Claude Code and run:

```
/resume
```

That reads `SCOPE.md`, the latest `outputs/final/`, and the most recent individual outputs, then either continues from where the last iteration left off or lets you drop a new question into the queue. To evaluate a specific tool against the spec instead, run `/resume evaluate <tool>`.

## Directory structure

```
├── CLAUDE.md                    # Instructions for Claude Code
├── SCOPE.md                     # Live spec: pain points + requirements (READ FIRST)
├── context/
│   ├── from-human/              # Background info and notes
│   ├── from-history/            # Compacted findings from prior iterations
│   └── from-internet/           # Saved web sources
├── prompts/run/{initial,subsequent}/   # Prompts, in execution order
├── outputs/
│   ├── individual/              # Per-prompt research outputs
│   ├── aggregated/{markdown,pdf}/
│   └── final/                   # Synthesis + implementation briefs
├── slash-commands/              # Custom Claude Code commands
└── notes/
```

## Slash commands

| Command | Purpose |
|---|---|
| `/resume` | Pick up from the last iteration, or evaluate a specific tool against `SCOPE.md` |
| `/run-prompt` | Execute the next prompt in the queue |
| `/compact` | Summarise individual outputs into compacted history |
| `/aggregate` | Combine individual outputs into a single document |
| `/status` | Show research progress |

## Design philosophy

- **Filesystem as workflow engine** — folder structure defines the process
- **Markdown-native** — plain text, version-controlled, portable
- **Compaction over RAG** — summarise and feed back rather than vectorise
- **Iterative deepening** — each round builds on the last
- **Living spec** — `SCOPE.md` is updated every iteration as new pain points and requirements emerge

## License

MIT

---

For more Claude Code projects, see the [Claude Code Projects Index](https://github.com/danielrosehill/Claude-Code-Repos-Index).
