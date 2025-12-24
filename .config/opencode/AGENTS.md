# Agent Configuration

## extended thinking

<thinking_triggers>
use ("think hard", "think harder", "ultrathink") for:
- architecture decisions with multiple valid approaches
- debugging after initial attempts fail
- planning multi-file refactors
- reviewing complex PRs or unfamiliar code
- irreversible operations

skip for:
- simple CRUD, obvious fixes
- file reads, exploration, running commands
</thinking_triggers>

## grounded research

Clone repos to `~/reference/` for deep exploration when needed.

**workflow:**
1. `google_search` to find repo/author if unknown
2. clone to `~/reference/<repo>`
3. explore code directly — don't rely on search snippets

<examples>
- vllm TPU serving → clone vllm-project/vllm, vllm-project/tpu-inference
- jax bug → clone jax repo, read source
- hyprland features → google to find repo, then clone
- mimic library code → clone target library first
</examples>

## knowledge system

**location:** `~/private/knowledge/`

Modular markdown collections loaded on-demand. Preserves context by loading only what's needed.

### structure

```
knowledge/<topic>/
├── README.md        # index — always read first
├── <subtopic>.md    # specific knowledge
└── scripts/         # optional helpers
```

### commands

```bash
ls ~/private/knowledge/                          # list topics
cat ~/private/knowledge/<topic>/README.md        # read index
cat ~/private/knowledge/<topic>/<subtopic>.md    # load file
```

### triggers

| user says | action |
|-----------|--------|
| "add to knowledge" | create/update knowledge file |
| "memorize this" | create/update knowledge file |
| "check your knowledge" | read relevant README.md |
| "load knowledge about X" | cat specific file |

### creating knowledge

1. `mkdir -p ~/private/knowledge/<topic>`
2. create `~/private/knowledge/<topic>/<subtopic>.md`
3. update `README.md` index table

**example:** learned context parallelism in jax
→ `~/private/knowledge/jax/context_parallelism.md`
→ add entry to `~/private/knowledge/jax/README.md`

see `~/private/knowledge/add.md` for full guide.

### sync

if on remote: rsync knowledge to local after changes.

## project conventions

- use project's package manager (bun, uv)
- always run with uv for python project
- never manually edit package.json, pyproject.toml
- for long processes (10-30 min), use pty background — verify code works first

### commits
- only commit when asked
- lowercase messages, short and direct
- use git cli (graphite only if explicitly requested)

