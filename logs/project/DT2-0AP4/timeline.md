# Timeline — DT2-0AP4: `z Enter` opens task worktree (keep `z w`/`z s`)

Task: DT2-0AP4 (status active, project dotfiles2).
Ask: user runs aven inside tmux and wants `z Enter` on a task to open the
worktree via `workmux open` / `workmux add`, named after the task, so the
tmux client auto-switches. Correction (2026-10-08): do NOT remove `z w` /
`z s` — just add `z Enter`.

## 2026-10-08 — investigation (agent: muse)

- Marked task `active` in aven.
- Prior art (DT2-X4Q1): `.config/aven/commands/workmux-add` (`z a`, 3
  prompts: fzf agent, free-type worktree name, `$EDITOR` prompt) plus
  dashboard scripts (`z w`, `z s`). All kept untouched per correction.
- Live wiring: `~/.config/aven/commands` is a symlink to the MAIN checkout
  (`/home/carlesoctav/dotfiles2/.config/aven/commands`), NOT this worktree.
  So a new script here activates only after merge to master. `tui.commands`
  YAML in `~/.config/aven/config.yaml` is local-only by design (never in
  repo) — same split as DT2-X4Q1.
- `workmux add --open-if-exists` covers both halves of the ask ("open, or
  add"): creates the worktree when missing, opens/switches when it exists
  (like `tmux new -A`). No need to branch on `workmux open` vs `add`.
- Enter key token: upstream docs
  (`docs/src/content/docs/custom-commands.md`, raine/aven) say each `keys`
  entry is a case-sensitive space-separated sequence; named keys include
  `Enter` (capital E). Only `Up`/`Down`/`PageUp`/`PageDown` are banned after
  a prefix, so `z Enter` is legal. Probed locally with
  `AVEN_CONFIG_DIR=/tmp/aven-keytest` + `aven doctor`: `[z Enter]`
  loads clean (`ok config file`); `[z ret]`, `[z <enter>]`, `[z CR]`,
  bare `[enter]`, `[ctrl-m]` are rejected as invalid configuration.
  (Baseline `overall: error` is pre-existing: daemon not installed/running.)

## 2026-10-08 — implementation (agent: muse)

- New `.config/aven/commands/workmux-open` (executable, `bash -n` clean):
  zero-prompt fast path of `workmux-add`. Same context parsing (exactly-one
  target, durable id + ref) and project-dir resolution
  (`aven project path list` -> `nvim_file` dirname -> `invocation.cwd`).
  Differences: worktree name = lowercase task ref (no free-type), prompt =
  default template inline (no `$EDITOR`), agent = first available of
  `muse`, `agy` with no fzf (omits `-a` entirely when neither exists).
  Runs `workmux add <name> -p <prompt> [-a <agent>] --open-if-exists`
  from the project dir, then leaves an aven handoff note (same wording
  family as `workmux-add`).
- `z w` / `z s` scripts and YAML entries untouched.
- Validation (hermetic, throwaway shims in /tmp, kept out of repo):
  fake v1 context for DT2-0AP4 + shimmed `workmux`/`aven`/`fzf` assert the
  exact argv (`add dt2-0ap4 -p <template> -a muse --open-if-exists` from the
  project dir), the no-agent fallback (no `-a` flag), and the note call.
  `tui.commands` block with `keys: [z Enter]` validated via
  `AVEN_CONFIG_DIR=/tmp/aven-cfgtest`: `aven doctor` -> `ok config file`
  (only pre-existing daemon findings).
- Live TUI check (keypress inside tmux) not possible headless.

## Activation (for user — NOT done yet)

1. Merge this worktree to master (`/merge`) so `workmux-open` lands in
   `/home/carlesoctav/dotfiles2/.config/aven/commands/` (live symlink
   target). Until then the YAML entry would point at a missing program.
2. Append to `~/.config/aven/config.yaml` under `tui.commands`
   (keep `image_optimization: off` literal — PyYAML rewrites it to `false`,
   which aven rejects):

```yaml
    - name: workmux-open
      description: Open focused task worktree (create if missing)
      program: ~/.config/aven/commands/workmux-open
      keys: [z Enter]
      target: focused
      execution: terminal
      on_success: refresh
```

3. Restart the TUI; `:workmux-open` should also appear in the palette.

## Open questions / notes for next agent

1. `add --open-if-exists` with `-p`/`-a` on an EXISTING worktree: assumed
   to just switch (flags ignored); only the create path was exercised via
   shims, and `workmux list` shows live worktrees but no live create/open
   was run from this worktree (would disturb the user's tmux client).
2. If the user later wants the quick path to also skip agent startup
   entirely (plain shells), drop `-a` from the script — one-line change.
