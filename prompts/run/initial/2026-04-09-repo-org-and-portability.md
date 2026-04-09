# Prompt — Repo organisation & portability

Date: 2026-04-09

## Context

I use `~/repos/github/` to store GitHub repos; that's where GitKraken clones by default, and I bookmark frequently-used ones in Dolphin. Over time it becomes a large disorganised mess, so I group them into topical subfolders. Claude can do that reorganisation efficiently and I can make spot changes afterwards.

**Problems:**
1. Reorganising breaks Dolphin bookmarks (absolute paths).
2. I want to version-control not just the currently cloned repos (a subset of everything I work on) but also the *organisational structure itself*, so I can quickly replicate it on other machines.

## Question

Can you think of any fluid ways to handle this — keeping the topical grouping, preserving bookmarks across moves, and making the whole layout portable across machines?
