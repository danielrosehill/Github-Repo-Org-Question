# SCOPE — Claude-Research-Workspace-General-Template

## What this repo is

The **lean, general-purpose** Claude Code research workspace template. It is the **base** that `Claude-Research-Space-Public-Template` extends.

## What it does NOT include

Compared to `Claude-Research-Space-Public-Template`, this template deliberately omits:

- Publishing config (`.env.example`, `publishing-config.example.json`)
- `scripts/` publishing helpers
- `private/` split and `outputs/published/` target
- `voice-notes/` capture area
- Slash commands: `export`, `publish-readme`, `setup-publishing`, `voice-note`

## When to use this one

Use this template when you want a **clean research workspace** with no publishing pipeline, no public/private split, and no voice-note tooling — just the core research workflow.

## When to use the other one instead

If the workspace needs to publish outputs (GitHub, site, etc.) or wants voice-note capture and a public/private split, use `Claude-Research-Space-Public-Template` instead.

## Relationship

`Claude-Research-Workspace-General-Template` = base (this repo)
`Claude-Research-Space-Public-Template` = base + publishing layer

Improvements to shared files should generally flow base → public.
