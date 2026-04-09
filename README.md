[![Claude Code Projects Index](https://img.shields.io/badge/Claude%20Code-Projects%20Index-blue?style=flat-square&logo=github)](https://github.com/danielrosehill/Claude-Code-Repos-Index)

> **See also**: [Open Research Workspace](https://github.com/danielrosehill/Claude-Research-Space-Public-Template) — a variant of this template designed for public/open-source research (adds export commands, publishing integrations, and public-audience formatting).

# Github-Repo-Org-Question

Research workspace for investigating approaches to organising a large collection of personal GitHub repositories — structure, indexing, tagging, and ongoing maintenance strategies.

Built on Daniel's Claude Research Workspace template: iterative AI-assisted research with Claude Code as the execution engine.

## Concept

This repository is a **structured research workspace** — not a traditional codebase. It uses a folder-based pattern where:

- **Context** folders hold background information and compacted history
- **Prompt** folders manage the research queue
- **Output** folders capture and aggregate findings
- A **compaction loop** feeds previous findings back as context for deeper investigation

The filesystem acts as both the workflow engine and the knowledge base. No databases, no vector stores, no complex tooling — just folders, markdown files, and Claude Code.

## Getting Started

### 1. Fork or use as template

Click **Use this template** on GitHub, or fork and clone.

### 2. Set up your research topic

Edit `context/from-human/research-brief.md` with your research topic, scope, and any background information.

### 3. Write your first prompt

Create a prompt in `prompts/run/initial/` describing what you want to investigate. See `prompts/run/initial/example-initial-prompt.md` for the format.

### 4. Run it

Open the repo in Claude Code and tell it to run the prompt:

```
Run the prompt in prompts/run/initial/
```

### 5. Iterate

Review the output in `outputs/individual/`, write follow-up prompts in `prompts/run/subsequent/`, and keep going. When context grows large, ask Claude to compact.

## Directory Structure

```
├── CLAUDE.md                    # System instructions for Claude Code
├── context/
│   ├── from-human/              # Your background info and notes
│   ├── from-history/            # Compacted findings from prior iterations
│   └── from-internet/           # Saved web sources and references
├── prompts/
│   ├── drafting/                # Prompts under development
│   ├── queue/                   # Ready to run (ordered)
│   └── run/
│       ├── initial/             # First-pass research prompts
│       └── subsequent/          # Follow-up prompts
├── outputs/
│   ├── individual/              # Per-prompt research outputs
│   ├── aggregated/
│   │   ├── markdown/            # Combined research documents
│   │   └── pdf/                 # PDF exports
│   └── final/                   # Polished deliverables
├── slash-commands/              # Custom Claude Code slash commands
└── notes/                       # Working notes and methodology
```

## Workflow

```
 ┌─────────────┐
 │   Context    │◄──────────────────────┐
 │  (from-human │                       │
 │  from-history│                       │
 │  from-internet)                      │
 └──────┬──────┘                        │
        │                               │
        ▼                               │
 ┌─────────────┐                        │
 │   Prompt     │                       │
 │  (queue/run) │                       │
 └──────┬──────┘                        │
        │                               │
        ▼                               │
 ┌─────────────┐      ┌────────────┐    │
 │   Claude     │─────►│  Output    │    │
 │   Code       │      │ (individual)   │
 └─────────────┘      └──────┬─────┘    │
                             │          │
                     ┌───────┴───────┐  │
                     │  Compaction   │──┘
                     │  (summarise   │
                     │   → history)  │
                     └───────┬───────┘
                             │
                             ▼
                      ┌────────────┐
                      │ Aggregation│
                      │ (combined  │
                      │  markdown/ │
                      │  pdf)      │
                      └────────────┘
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/run-prompt` | Execute the next prompt in the queue |
| `/compact` | Summarise outputs into compacted history |
| `/aggregate` | Combine individual outputs into a single document |
| `/status` | Show research progress (prompts run, outputs generated, queue length) |

## Spinning Up a New Research Project

1. Use this repo as a GitHub template
2. Replace `context/from-human/research-brief.md` with your topic
3. Clear the example prompts and outputs
4. Start researching

## Design Philosophy

- **Filesystem as workflow engine**: Folder structure defines the process
- **Markdown-native**: Everything is plain text, version-controlled, portable
- **Compaction over RAG**: Summarise and feed back rather than vectorise
- **Iterative deepening**: Each round builds on compacted findings from the last
- **No infrastructure required**: Just Claude Code and a git repo

## License

MIT

---

For more Claude Code projects, visit my [Claude Code Projects Index](https://github.com/danielrosehill/Claude-Code-Repos-Index).
