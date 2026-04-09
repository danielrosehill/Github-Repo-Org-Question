# Natural-Language Local AI Assistant for `~/repos/github/`

Date: 2026-04-09
Status: Exploratory — alternative frame to the settled Rofi+SQLite+GRM stack in `outputs/final/2026-04-09-repo-management-synthesis.md`.

## Key Findings

- **Nothing off the shelf does this well as of April 2026.** Every candidate is either (a) a generic "chat with documents" wrapper (AnythingLLM, LM Studio RAG, GPT4All, FolderChat, LlamaIndex RAG CLI) that indexes file *contents* but has no concept of "repo" as a first-class entity, no frecency, and no action layer; or (b) a code-assistant (Continue.dev, aider, Cursor, Cody) that is scoped *inside* one repo, not *across* a fleet of hundreds. None of them answer "the repo where I was messing with whisper fine-tuning" and then open it in Claude Code.
- **The right move is to build a thin NL layer over the SQLite index the settled stack already produces.** The index is the hard part; it already exists (or will in a week). Adding natural-language search is a 150-line Python script: Ollama with a small tool-calling model, two tools (`search_repos`, `open_repo_action`), and the same DB. No new vector store required for the MVP — fuzzy-match on metadata with LLM-reranked top-K is sufficient and dramatically faster than embedding RAG.
- **This augments rather than replaces Rofi.** Rofi remains the 200ms muscle-memory path for "I know the repo name." The NL assistant is the escape hatch for "I don't remember the name but I remember what it was about." Two different cognitive modes, same backing DB.
- **Recommended model:** `qwen2.5:7b-instruct` or `qwen2.5:14b-instruct` via Ollama — both have robust tool-calling in 2026 and fit comfortably on a capable desktop. Avoid llama3.x for tool calling (still flaky per community reports).

## 1. Existing tools surveyed

| Tool | What it is | Fit for this use case | Verdict |
|---|---|---|---|
| **AnythingLLM** | Desktop app, file-search agent, multi-workspace RAG | Can be pointed at `~/repos/github/` and granted filesystem access; agent can grep/list files. No repo-identity concept, no frecency, no GitHub Projects awareness, no per-result action hotkeys. Heavy GUI. | Overkill + wrong primitive. Close but misses the model. |
| **LM Studio (RAG mode)** | Local LLM GUI with document chat | Same issue: indexes file contents, not repo metadata. No action layer. | No. |
| **GPT4All / PrivateGPT variants** | Local RAG over a folder | Same as above. Document-centric, not entity-centric. | No. |
| **FolderChat** | Tree-checkbox RAG over folders, Gemma embeddings | Windows-first, and still document-RAG not repo-RAG. | No. |
| **LlamaIndex `rag` CLI** | Terminal RAG REPL over a directory | Closest *framework* but not a turnkey answer; you'd still build the repo-entity layer yourself. If building, LlamaIndex or pure Python+sqlite is a coin-flip — pure Python wins on leanness. | Framework option if building. |
| **Continue.dev / aider / Cursor / Cody** | In-repo code assistants | Scoped *inside* a single repo. Wrong scope entirely. | No. |
| **Sourcegraph Cody (self-hosted)** | Code search across repos with LLM | Actually does cross-repo semantic code search, but it's a heavy Docker stack, content-focused not metadata-focused, and ruled out in prior iteration as overkill. | No. |
| **Ollama + `llm` CLI (Simon Willison) + `llm-embed-ollama`** | CLI plumbing for embeddings/chat | Building blocks, not a product. Useful if building. | Building block. |
| **txtai** | All-in-one semantic search + LLM orchestration framework | Interesting if you later want semantic search over READMEs. Overkill for MVP. | Later, maybe. |
| **KDE/Plasma native options** | KRunner, Baloo | Baloo indexes file contents but has no LLM/NL layer and no repo semantics. KRunner Python runners still shaky on Plasma 6. | No. |

**Conclusion:** no turnkey tool. The gap is that all "chat with filesystem" tools model documents, and all code assistants model *one* repo. Nothing models "a fleet of repos as searchable entities with actions." This is the same ~500 LOC gap the previous synthesis identified, just from a different angle.

## 2. Minimal bootstrap architecture

Reuse the SQLite index from the settled stack. Add one script. That's it.

```
┌────────────────────────────────────────────────────────────┐
│  NL CLI / hotkey     repo-ask "the whisper fine-tune one" │
│   ↓                                                        │
│  Ollama (qwen2.5:7b-instruct, tool-calling)               │
│   ↓ tools:                                                 │
│      search_repos(query, k=8)     → SQL LIKE/FTS5 on DB   │
│      open_repo(remote_url, action) → shells out           │
│   ↑ reads                                                  │
│  ~/.local/share/repo-index.db  (the same SQLite index)    │
└────────────────────────────────────────────────────────────┘
```

### Components

1. **Index (unchanged):** the existing `~/.local/share/repo-index.db` with `name`, `description`, `topics`, `projects`, `last_commit_date`, `open_count`, `local_path`. Enable an FTS5 virtual table over `name || description || topics || projects` — trivial to add and gives sub-5ms fuzzy lookup over thousands of rows.

2. **LLM runtime:** Ollama. Model = `qwen2.5:7b-instruct` (fast, solid tool calling) or `qwen2.5:14b-instruct` if the machine has headroom. Avoid llama3.x and gemma2 for tool calling in 2026 — community reports still flag reliability issues. Alternative: `gpt-oss:20b` if Daniel already has it pulled.

3. **Two tools, defined in Ollama tool-calling JSON schema:**
   - `search_repos(query: str, k: int = 10)` — runs `SELECT ... FROM repos_fts WHERE repos_fts MATCH ? ORDER BY bm25(repos_fts) * (1 + open_count*0.01) DESC LIMIT ?`. Returns name + description + topics + local_path + remote_url. The LLM does the reranking and picks the best match from candidates; no embedding RAG needed at this scale.
   - `open_repo(remote_url: str, action: Literal["claude", "terminal", "vscode", "dolphin", "github"])` — shells out to the matching command (`konsole -e claude`, `code`, `xdg-open`, etc.). Bumps `open_count` on success. This is identical to the Rofi action layer — literally the same shell functions.

4. **The NL loop:** ~100 lines of Python. Takes a query, sends it + tool schemas to Ollama, executes tool calls, loops until the LLM emits a final answer with a concrete action. Stream tokens to the terminal so it feels live. Optional confirmation step before executing destructive or ambiguous actions.

5. **Exposure surfaces:**
   - **CLI:** `repo-ask "whisper fine-tune"` — the primary, scriptable entry point.
   - **Hotkey:** `Meta+Shift+R` bound via KDE Custom Shortcuts → runs `konsole -e repo-ask` with a small input dialog (`kdialog --inputbox`), then hands off to the CLI.
   - **Later:** Albert extension that delegates "?" prefixed queries to `repo-ask`, so Albert stays instant-fuzzy for known-name lookups but gains NL as a fallback mode.
   - **Not recommended yet:** KDE Plasma widget. Plasmoid dev on Plasma 6 is still rough; CLI+hotkey covers the value at 1/10 the effort.

### Why no vector DB in the MVP

At hundreds of repos with ~100-500 chars of metadata each, total corpus is ~100KB. FTS5 full-text search over that is effectively free and returns in microseconds. Embedding RAG adds: an ingestion pipeline, stale-embedding problems, a second dependency (chroma / sqlite-vec), and does not meaningfully improve recall when the LLM itself is doing the final rerank over the top-20 FTS candidates. **Add embeddings later only if fuzzy-over-metadata stops recalling the right repo** — which the settled stack already assumed wouldn't happen for 99% of queries.

### Optional v2: README-aware retrieval

If NL queries start failing on repos where the README describes the topic but the name/description doesn't (e.g. "the one where I tried ROCm with that custom kernel" and neither name nor description mention ROCm), add:
- `sqlite-vec` extension + `nomic-embed-text` via Ollama
- Embed the first 2KB of each README on index update
- Extend `search_repos` to do hybrid FTS + vector search
- Est. ~50 additional LOC, ~5 min one-time ingestion for 500 repos

Flag this as v2, not v1. The previous synthesis deliberately parked README semantic search as premature — that judgment still holds for the MVP.

## 3. Trade-offs vs the settled Rofi+SQLite+GRM stack

| Dimension | Rofi launcher | NL assistant |
|---|---|---|
| **Latency** | ~50-100ms end-to-end | ~1-4s end-to-end (Ollama inference + tool call + action). Tolerable for fuzzy-intent queries; unacceptable for muscle-memory "I know the name" lookups. |
| **Accuracy on known names** | Near perfect (fuzzy match + frecency) | Perfect but wasteful — LLM for a substring match is silly. |
| **Accuracy on fuzzy intent** | Bad — you must know a keyword that's in name/description/topics. "whisper fine-tune" only hits if you tagged it. | Good — the LLM can rerank on partial recall, synonyms, and context ("that israeli prep stuff" → matches repos tagged `hebrew`, `aliyah`, `israel`). |
| **Action execution** | First-class via `-kb-custom-N` | Via LLM tool calling — works but adds one round-trip. |
| **Cost of staleness** | Index staleness hurts both equally (same DB). | Same. |
| **Cognitive load** | Hotkey + 3 keystrokes + Enter. | Hotkey + type a sentence + read + confirm. |
| **Replaces the frecency launcher?** | — | **No. Augments.** Rofi is the default, NL is the "I don't remember" fallback. |

**Recommendation:** ship Rofi first (as already planned), then add `repo-ask` as a second entry point a week later. They share the DB and the action layer entirely — there's no duplicated work. The NL assistant is additive, scoped, and cheap.

## 4. How action execution actually works

Ollama's tool-calling API (stable since late 2024, well-supported in 2026) expects the client to:

1. Send the user query + a list of tool JSON schemas to `/api/chat`.
2. Receive back either a final message or one or more `tool_calls` entries with `name` + `arguments`.
3. Execute the tool client-side. For `open_repo(remote_url="git@github.com:danielrosehill/whisper-finetune", action="claude")`:
   ```python
   row = db.execute("SELECT local_path FROM repos WHERE remote_url=?", (remote_url,)).fetchone()
   subprocess.Popen(["konsole", "--workdir", row["local_path"], "-e", "claude"])
   db.execute("UPDATE repos SET open_count=open_count+1, last_opened=? WHERE remote_url=?", (now, remote_url))
   ```
4. Append the tool result message and send back to Ollama to get the final natural-language confirmation.

**Confirmation gate:** for any action, print the matched repo + proposed action and require Enter before executing. One extra keystroke; eliminates the whole class of "LLM opened the wrong thing" failures. Uncertain: whether to also gate read-only surfacing ("here's what I think you mean") — probably yes for ambiguous queries (top-1 score < threshold), no for confident ones.

**Claude Code specifically:** `konsole --workdir <path> -e claude` or `konsole --workdir <path> -e bash -c 'claude; exec bash'` if you want the shell to persist after Claude exits. Daniel's existing Rofi action script will already have this one-liner — reuse it verbatim.

## 5. Concrete build plan (if greenlit)

Assumes the Rofi+SQLite MVP from the synthesis is already in place (if not, build that first — it's a prerequisite).

1. **Day 1 (1 hour):** add FTS5 virtual table to `repo-index.db`; populate alongside existing rows in the hourly cron.
2. **Day 1 (30 min):** `ollama pull qwen2.5:7b-instruct`; smoke-test tool calling with a 20-line script.
3. **Day 2 (2 hours):** write `repo-ask` — ~150 lines of Python: argparse, Ollama client, two tool functions, loop, confirmation prompt, action dispatch reusing the Rofi action shell functions.
4. **Day 2 (15 min):** KDE Custom Shortcut `Meta+Shift+R` → `kdialog --inputbox "repo?" | xargs -I{} konsole -e repo-ask "{}"`.
5. **Week 2:** measure. How often does NL beat Rofi? Which queries fail? If README-blind failures dominate, add the hybrid embedding path from §2.

Total net-new effort over the already-planned stack: **~4 hours**. This is the cheapest feature in the whole research iteration.

## 6. Uncertainties and open questions

- **Tool-calling reliability of 7B-class local models on real-world queries.** Community consensus in 2026 is "qwen2.5 works, most others are flaky" but this is a moving target — benchmark on Daniel's actual queries before committing to a model. `gpt-oss:20b` may outperform if already available.
- **Whether the LLM will hallucinate remote URLs** when the FTS result is ambiguous. Mitigation: the `open_repo` tool validates `remote_url` exists in the DB and refuses unknown keys. Belt-and-braces.
- **Whether 1-4s latency is acceptable as a fallback.** Unknown until used. If it feels slow, swap to a 3B model (`qwen2.5:3b-instruct`) — may lose some reranking quality but stay under 1s.
- **Voice input layer.** Out of scope here, but a whisper.cpp front-end piping to `repo-ask` would make "open my whisper fine-tuning repo" a literal voice command. Trivial addition once the text path works. Flag as a fun v3.
- **Publishing as OSS.** The same note from the prior synthesis applies — this is ~650 LOC total including the NL layer, and the NL layer is the part most differentiating for prospective users. Worth considering.

## 7. Recommendation

**Build the minimal NL assistant as an addition to the settled stack, not a replacement.** Specifically:

1. Ship Rofi + SQLite + GRM as already planned — that's the 200ms daily driver.
2. Add `repo-ask` (Ollama + qwen2.5:7b + two tools + FTS5) as a secondary Meta+Shift+R entry point. ~4 hours of work over the planned stack.
3. Defer embedding-based README retrieval until fuzzy+FTS+LLM-rerank demonstrably fails.
4. Do not adopt AnythingLLM / LM Studio / FolderChat / any other "chat with filesystem" tool — they model the wrong primitive and would require more work to bend into shape than building the thin layer from scratch.

The key insight: **the hard part of this problem is the repo-entity index, not the NL layer.** The settled stack already solves the hard part. Adding NL on top is small, cheap, and additive — and it's the only form of "local AI assistant over my repos" that will actually feel like it understands repos rather than files.

## Sources

- [AnythingLLM agent usage](https://docs.useanything.com/agent/usage)
- [LlamaIndex RAG CLI](https://docs.llamaindex.ai/en/stable/getting_started/starter_tools/rag_cli/)
- [FolderChat](https://github.com/straygizmo/folderchat)
- [LM Studio RAG docs](https://lmstudio.ai/docs/app/basics/rag)
- [Ollama tool calling (IBM tutorial)](https://www.ibm.com/think/tutorials/local-tool-calling-ollama-granite)
- [Ollama embeddings docs](https://docs.ollama.com/capabilities/embeddings)
- [Ollama library (qwen2.5, gpt-oss)](https://ollama.com/library)
- [llm-embed-ollama plugin](https://github.com/sukhbinder/llm-embed-ollama)
- [local-llm-rag-chromadb example](https://github.com/sbj1198/local-llm-rag-chromadb)
- [txtai framework](https://github.com/neuml/txtai)
- [Ollama web search and agent capabilities (DeepWiki)](https://deepwiki.com/ollama/ollama/7.6-web-search-and-agent-capabilities)
- [Ask Your Codebase Anything with Ollama + RAG (Medium)](https://medium.com/@farissyariati/ask-your-codebase-anything-using-ollama-embeddings-and-rag-c65081a5ef20)
- Prior research: `outputs/final/2026-04-09-repo-management-synthesis.md` and `SCOPE.md` in this workspace.
