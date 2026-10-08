# Grill — DT2-X4Q1: new aven command(s) (Final)

Accepted by user go-ahead "just implement already" (2026-10-08); design
approved and implemented in the same turn.

Task: DT2-X4Q1 (`add a new aven command,`, status active, project dotfiles2).
Upstream references: https://github.com/alxhall/aven-nvim (pattern source),
primary aven repo: https://github.com/raine/aven (from `aven update` release URL).

## Researched facts (not asking again)

- New aven TUI commands = executable script + `tui.commands` entry in
  `~/.config/aven/config.yaml` (name, description, program, keys,
  detail_keys, target, execution, on_success). Local config currently has
  `tui.commands: []` and no `~/.config/aven/commands/` dir.
- Context arrives as JSON (`version == 1`, exactly-one-target check,
  `targeting.targets[0].id/ref`, `invocation.db_path`, `invocation.aven_exe`).
  aven-nvim reads it via `$AVEN_COMMAND_CONTEXT` file (open) or stdin (delete).
- aven 0.1.46 installed; aven-nvim tested against 0.1.39, API experimental.
- Agent binaries present: `muse`, `agy`, `codex` (all in ~/.local/bin).
- Requested detection strategy: binary availability, `muse` + `agy` only for now.

## Settled decisions

- Command 1 ("workmux-add flow"): from task list or task detail, run
  `workmux add [worktree] -p <prompt> --agent <agent>` for the selected task.
  Three prompts: [agent selection] [worktree] [prompt]. (user, 2026-10-08)
- Default prompt text: "please work on this task [id], document your progress
  on ./logs/project/[task_id]/[timeline].md, and later put notes so another
  agent aware of ur try". Prompt is editable per-invocation, e.g. `/grill`
  to grill first. (user, 2026-10-08)
- Agent detection via binary availability, `muse` + `agy` for now. workmux
  supports this: `-a/--agent` takes any command; `agy` is built-in, `muse`
  works as custom agent command. (researched, 2026-10-08)
- Upstream custom-command contract (raine/aven docs, 0.1.46): script +
  `tui.commands` entry; `execution: terminal` gives the child the TTY
  (needed for interactive pickers) with context via `$AVEN_COMMAND_CONTEXT`;
  `target: focused` fits single-task operation; `wait` reads JSON from stdin.
  (researched, 2026-10-08)

## Unresolved questions

1. Q2 (settled): `z a` = workmux-add flow; letters `z w` and `z s`
   accepted for the other two bindings. (user, 2026-10-08)
2. Q3 (settled): `z w` = workmux dashboard scoped to path/project under
   cursor; `z s` = workmux dashboard agents view. (user, 2026-10-08)
3. Q4 (settled): `z w` script resolves the selected task's project path
   (via `aven project path` mappings, else task `nvim_file` dir, else aven
   cwd), `cd`s there, then runs `workmux dashboard`. Verified in workmux
   source that dashboard takes no path flag and scope is only all/session,
   so this is `cd <path> && workmux dashboard` with manual `/`/`F`
   filtering once open. (user+research, 2026-10-08)
4. Q5/Q7 (settled): `z s` = `workmux dashboard --tab agents`, unscoped.
   (user, 2026-10-08)
5. Q8 (settled): scripts live in dotfiles2 under `.config/aven/commands/`,
   deployed via stow. `tui.commands` YAML stays local-only. (user, 2026-10-08)
6. Q9 (settled): `on_success: refresh` on all three commands. (user, 2026-10-08)

## Scope contract (proposed — awaiting explicit acceptance)

**Deliverable (in scope):** three executables in dotfiles2
`.config/aven/commands/` (`workmux-add`, `workmux-dashboard-here`,
`workmux-dashboard-agents`) + the exact `tui.commands` YAML block to merge
into local `~/.config/aven/config.yaml` (stow deploys scripts; YAML edit
stays manual/local). Keys `z a` / `z w` / `z s`, `target: focused` for all
three (`z w` resolves the project from the selected task),
`execution: terminal`, `on_success: refresh`.
Validation: `aven doctor` clean + dry-run of each script's resolution
logic. Interview ends with this doc marked Final on acceptance.

**Out of scope:** the truncated second command (`workmux send` flow —
separate grill), stow wiring itself, `workmux setup`/hooks, model-level
selection inside agents, syncing commands across devices.

**Done means:** scripts executable in repo; YAML block documented;
`aven doctor` passes; DT2-X4Q1 has handoff notes for the implementer.

**Staging:** accepting this record approves design only — implementation
happens only on a separate explicit request.

## Implementation (done 2026-10-08, on explicit "just implement already")

Scripts (executable, `bash -n` clean; no shellcheck on machine):
- `.config/aven/commands/workmux-add` — `z a` flow (agent fzf over
  muse/agy binaries, worktree default = lowercase ref, `$EDITOR` prompt
  prefill, `workmux add -p -a --open-if-exists` from project dir, aven
  handoff note). Project dir: `aven project path list <key>` →
  `nvim_file` dirname → `invocation.cwd`.
- `.config/aven/commands/workmux-dashboard-here` — `z w`: cd to project
  dir, `exec workmux dashboard` (falls back to plain dashboard if
  unresolvable).
- `.config/aven/commands/workmux-dashboard-agents` — `z s`:
  `exec workmux dashboard --tab agents`.

Validation (hermetic, /tmp/aven-cmd-test-run.sh kept out of repo):
- Fake context + shimmed workmux/aven-note: `add dt2-x4q1 -p <template>
  -a muse --open-if-exists` from `/home/carlesoctav/dotfiles2`, note call
  with durable id — all exact. Dashboard-here: cwd=project dir.
  Dashboard-agents: `dashboard --tab agents`.
- `tui.commands` block validated via `AVEN_CONFIG_DIR=/tmp/aven-cfgtest`:
  `aven doctor` → `ok config file` (only pre-existing daemon findings).
  TUI binary fails headless only at terminal init — no catalog errors.
- One test artifact was a real note on DT2-X4Q1 from the first run (aven_exe
  bypassed the shim); deleted via `note-delete` (note=61MYBFRFFYNE6CTP).

Not verifiable headless (for live check): multi-agent fzf picker branch,
interactive `$EDITOR` edit, in-TUI `z a/z w/z s` keypresses.

Manual steps left for user (outside repo by design):
1. `stow .` (or link) so scripts land in `~/.config/aven/commands/`.
2. Merge this block into `~/.config/aven/config.yaml` under `tui:` (keep
   `image_optimization: off` literal — PyYAML rewrites it to `false`,
   which aven rejects):

```yaml
tui:
  commands:
    - name: workmux-add
      description: Dispatch selected task to a workmux agent worktree
      program: ~/.config/aven/commands/workmux-add
      keys: [z a]
      target: focused
      execution: terminal
      on_success: refresh
    - name: workmux-dashboard-here
      description: Open workmux dashboard from the task project path
      program: ~/.config/aven/commands/workmux-dashboard-here
      keys: [z w]
      target: focused
      execution: terminal
      on_success: refresh
    - name: workmux-dashboard-agents
      description: Open workmux dashboard on the agents tab
      program: ~/.config/aven/commands/workmux-dashboard-agents
      keys: [z s]
      target: focused
      execution: terminal
      on_success: refresh
```

3. Restart the TUI; `:workmux-add` should also appear in the palette.

## Recovery incident (2026-10-08, resolved)

`~/dotfiles2/.config` and `~/.config` share inodes file-by-file (same
filesystem objects, not symlinks), so replacing the deployed copies with
symlinks to the repo created self-loops (`Too many levels of symbolic
links`). Fixed by deleting the loops and rewriting the three scripts as
regular files — no symlinks anywhere. Consequence: repo copy and live copy
are the same file, so no stow/sync step is needed or wanted for this
directory; editing either path edits both. Re-validated after restore:
`bash -n` clean, hermetic dispatch test exact, `aven doctor` → ok.
5. Q6 (settled): worktree prompt = free-type with lowercase task ref as
   prefilled default (e.g. `dt2-x4q1`); `workmux add` passes
   `--open-if-exists`. (user, 2026-10-08)
6. `za` mechanics verified: `aven project path list [PROJECT]` resolves
   project dirs; `fzf` present for pickers, `EDITOR=nvim` for prompt edit;
   no gum/dialog. Script reads context from `$AVEN_COMMAND_CONTEXT`
   (`execution: terminal`), `target: focused`.
2. Dashboard line: one command or several? What does "path under the cursor"
   resolve to (selected task's project path? `nvim_file` metadata? cwd?)?
   `workmux dashboard` only filters by session/tab, not path.
3. "Primary repo" / worktree prompt semantics: new branch name, or pick an
   existing worktree? Where is the worktree created (task's project dir)?
4. Second command ("actually implement the…" — description truncated):
   `workmux send` to the created agent? Separate grill topic.
5. Script home: `~/.config/aven/commands/` direct vs versioned in dotfiles2?
6. `on_success` for the add-flow (`stay`/`refresh` vs `quit` — workmux
   switches the tmux client to the new session).

## Scope contract (pending acceptance)

- Boundary, done-criteria, and staging TBD after Q1–Q4 answers.
- Interview only: ending the grill never authorizes implementation.
