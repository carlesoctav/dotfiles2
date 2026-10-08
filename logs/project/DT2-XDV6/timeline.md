# DT2-XDV6 — aven custom command bug — timeline

## Reported symptoms (from task description)
1. `z a` (aven `workmux-add`) outside tmux does not pass the prompt, even when the branch is not master.
2. The tmux server must be running first.
3. Bare `workmux add master` fails with `Error: Failed to create worktree environment for branch 'master'`.

## Root causes (evidence-backed)

### 1. Outside tmux with server down: `add` fails, `open` fallback hangs
- `~/.local/state/workmux/workmux.log` at 2026-10-08T14:23:29Z and 14:23:41Z (`tmux_pane=None`, i.e. outside tmux):
  - `workmux add dt2-zy01 ... --mode window --parent-session carlesoctav_dotfiles2` -> `ERROR tmux is not running. Please start a tmux session first.`
  - Same for `workmux add master ...` at 14:23:41Z.
  - The following `workmux open ...` logs only `open:start ... mode_override=Some(Window)` with no completion before the next dispatch ~12s later — the fallback hangs when there is no server.
- Conclusion: `--parent-session` does not start the tmux server itself. The aven scripts never ensured the server, so outside-tmux dispatch fails outright when the server is down. A genuinely new branch is affected too, which matches "even tho the branch is not master".

### 2. Prompt dropped for existing worktrees (including master), and `send` never works for muse/agy
- `workmux add --open-if-exists -p ...` on an existing worktree delegates to `open` and drops `-p` (no PROMPT file, no agent injection). Example 14:18:01Z: `add dt2-fp4v ...` -> `open:switched to existing target`, no window created.
- The working-tree fix (uncommitted at session start) correctly wrote `.workmux/PROMPT-<name>.md` plus `workmux send` for the `existed` case, but `send` cannot succeed for `muse`/`agy`:
  - `ps aux` shows `muse-bin-1.4.4-R5419.1 -- PROBE-marker-...` (new worktree inside tmux, prompt passed as CLI args — works) versus bare `muse-bin-...` with no args in the `master` window (existing path, prompt lost).
  - Controlled probe (created `dt2-probe-xdv6` via `env -u TMUX workmux add ... -a muse`, server up): window + `muse -- PROBE-marker` created fine and PROMPT file written — so new-branch injection works once the server runs. But `workmux send dt2-probe-xdv6`, `workmux status`, and `workmux capture` all fail with `No agent running` / `No active agents` while pane `%8` is plainly `muse-bin-...` in that worktree. `muse`/`agy` are untracked (no hooks; not in workmux built-in agent list), so `send`-only delivery always reports "no running agent" even when the agent is up.
  - `workmux send master` at 14:26:20Z (DT2-XDV6 dispatch, `tmux_pane=None`) logs start with no completion for ~53s — the hung case.
- The `dispatch` script's tmux-paste fallback would cover untracked agents, but it requires `$TMUX` set and matches `^(muse|...)$` exactly, so it misses versioned binaries like `muse-bin-1.4.4-R5419.1`.

### 3. Bare `workmux add master` without `--open-if-exists`
- Expected behavior, not a workmux bug: `master` is already checked out at the main worktree (`workmux path master` -> `/home/carlesoctav/dotfiles2`, `(here)`), so a bare `add` tries to create `../dotfiles2__worktrees/master` for an already-checked-out branch and git rejects it. The aven scripts already use `add --open-if-exists --mode window --parent-session` with fallback to `open`, which is the correct handling. Direct CLI users should run `workmux open master` or `workmux add master --open-if-exists`.

## Fix (`.config/aven/commands/workmux-add`, `workmux-open`)
1. Ensure the tmux server before any workmux call when outside tmux:
   `tmux start-server` (idempotent; workmux still creates the parent session itself).
2. Cap the hung `send` with `timeout 15 workmux send ...`, then fall back to tmux paste into the worktree's agent pane when `send` fails. The fallback works without `$TMUX` (server only) and uses prefix match `^(muse|agy|claude|codex|gemini|grove|copilot|opencode|pi|omp)` so versioned binaries (`muse-bin-...`) are found. PROMPT file is still always written, so the worst case remains "stored, no running agent" with an explicit path.
3. Kept delivery scoped to the `existed` (open-if-exists/open-fallback) path where `-p` is known dropped, so new worktrees that already received the prompt as CLI args are not double-prompted.

## Verification
- `bash -n` clean on both scripts.
- `tmux start-server` verified idempotent inside tmux and via `env -u TMUX` (exit 0).
- Pane lookup for the broken case verified: `workmux path master` -> `/home/carlesoctav/dotfiles2`, lookup finds `%1` (`muse-bin-...`).
- `timeout 15 workmux send dt2-zy01` still fails fast with `No agent running` (exit 1), confirming the timeout only caps the hung case and the paste fallback is the live path for muse/agy.
- Controlled probe `dt2-probe-xdv6` (outside tmux, server up): `add -p -a muse --open-if-exists --mode window --parent-session` created worktree + window with `muse -- PROBE-marker` in `ps`; cleaned up via `workmux close` + `workmux remove` (branch gone, `git worktree list` clean, `carlesoctav_dotfiles2` windows back to pre-test set). No paste was fired into the live master agent during verification (lookup only).
- No committed test added: this repo (dotfiles) has no maintained test harness (no tests/, Makefile, CI, or package runner), so a test framework solely for two shell scripts would be disproportionate. Verification above is the narrowest honest check.
