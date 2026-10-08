# Timeline — DT2-8TXA: workmux add [worktree] session naming

Task: DT2-8TXA (`workmux add [worktree],`, status active, project dotfiles2).
Ask: session names from `workmux add` should mimic ctrl+f (prefix+f,
`tmux-sessionizer`): `[xxxx]_{worktree_name}`, master just `[xxxx]`, so that
prefix+C-w (workmux dashboard, worktrees tab) on master lands in the same
tmux session as ctrl+f.

## 2026-10-08 — investigation (agent: muse)

- Marked task `active` in aven.
- Sessionizer formula (`.config/scripts/tmux-sessionizer`, tracked):
  `selected_name = last-2-path-segments joined with '_'` (dots -> `_`).
  Master `/home/carlesoctav/dotfiles2` -> `carlesoctav_dotfiles2` (= [xxxx]).
  Worktree `/home/carlesoctav/dotfiles2__worktrees/dt2-8txa` ->
  `dotfiles2__worktrees_dt2-8txa` (ugly, and a *different* session from workmux).
- Live state: sessionizer session `carlesoctav_dotfiles2` (9 windows) and
  workmux session ` dotfiles2` (1 window) point at the same dir — sessions
  are fragmented, confirming the complaint.
- workmux naming (v0.1.271, session mode): session = `[icon]window_prefix+handle`;
  `window_prefix` supports only `{project}`. Verified with `--dry-run` probes:
  prefix `carlesoctav_dotfiles2_` -> worktree target
  `carlesoctav_dotfiles2_dt2-8txa` (matches clause 1 exactly).
- PROVEN (throwaway repo in /tmp, since removed): the main worktree follows
  the same prefix+handle rule (`PFX_wmprobe`), no special-casing. Therefore no
  static `window_prefix` can satisfy *both* "master -> [xxxx]" and
  "worktree -> [xxxx]_H" (master handle `dotfiles2` is non-empty). Config-only
  fix of the literal spec is impossible; cleaned up all probe sessions.
- Decision: implement the sessionizer side (tracked, committable) so ctrl+f is
  worktree-aware: worktree dir -> `{sessionizer(project-root)}_{handle}`
  (`carlesoctav_dotfiles2_dt2-8txa`), everything else unchanged (master stays
  `carlesoctav_dotfiles2`). Workmux-side convergence needs a per-invocation
  `--target-name` (or wrapper) — left as follow-up, see notes.

## 2026-10-08 — implementation (agent: muse)

- `.config/scripts/tmux-sessionizer`: extracted `session_name_for <dir>`,
  added `main` guard so the file can be sourced without side effects.
  Worktree detection: nearest ancestor whose parent basename ends in
  `__worktrees`; project root = `dirname(parent)/<name-minus-__worktrees>`;
  falls back to the legacy formula when no such ancestor exists or the
  project root dir is missing. Trailing slashes stripped.
- Verified with a throwaway sourcing probe (`/tmp/sess_test.sh`, kept for
  re-run): 8/8 green — master `carlesoctav_dotfiles2` (unchanged), worktrees
  `carlesoctav_dotfiles2_dt2-8txa|dt2-fx5b`, trailing-slash, nested-in-worktree,
  non-worktree (`carlesoctav_cv2`, `carlesoctav__config` unchanged), and
  missing-project-root fallback; plus a positive control where the project
  root exists (`/tmp/ghost__worktrees/wt1` -> `tmp_ghost_wt1`). `bash -n` clean.
  Convergence evidence: workmux `--dry-run` with
  `window_prefix: "carlesoctav_dotfiles2_"` resolves dt2-8txa to
  `carlesoctav_dotfiles2_dt2-8txa` — identical to the new sessionizer output.
  Live attach/switch not exercised (would disturb the user's tmux client).
- No maintained test added: repo has no shell-test harness (only
  `touchcursor-linux/test.c`, unrelated); a new framework for one naming
  function would be disproportionate.
- Live `~/.config/workmux/config.yaml` and main-tree `.workmux.yaml` left
  untouched (untracked local configs; user's call).
- Changes left uncommitted in worktree `dt2-8txa` for review/merge.

## 2026-10-08 — meta-template for window_prefix (agent: muse)

- Confirmed via `--dry-run`: only single-brace `{project}` expands
  (`{project}_` -> `dotfiles2_...`); `{{project}}` does NOT (`{{project}}_` ->
  `{dotfiles2}_...`, `{{ project }}` stays fully literal). There is no
  `{{...}}` templating in `window_prefix`.
- Added `.config/scripts/workmux-sync-prefix` (tracked, on PATH via
  `~/.config/scripts`): renders the literal prefix `<sessionizer-base>_`
  into `<root>/.workmux.yaml`, creating/replacing the `window_prefix` line
  and preserving all other keys. Uses no placeholders, so the above is moot.
- Verified on throwaway repo: fresh create, idempotent re-run, and replace
  with other keys preserved (`mode`/`nerdfont` untouched). `bash -n` clean.
  Re-run after moving/renaming the project dir. NOT run against the live
  `dotfiles2/.workmux.yaml` — user's call (master-dup caveat still applies).

## Open questions for user / next agent

1. Confirm [xxxx] = `carlesoctav_dotfiles2` (sessionizer name of master).
2. Workmux side: exact per-worktree names need `--target-name`
   (e.g. `workmux open dt2-8txa --target-name carlesoctav_dotfiles2_dt2-8txa`;
   unknown whether dashboard jumps persist it — unverified). Alternative:
   project `.workmux.yaml` `window_prefix: "carlesoctav_dotfiles2_"` matches
   worktrees but dups master (`..._dotfiles2`) if master is ever opened via
   dashboard — prefer ctrl+f for master.
3. Consider `default_session: carlesoctav_dotfiles2` so merge/remove drops
   back into the sessionizer master session (unverified, low risk).

## 2026-10-08 — merge (agent: muse, via /merge)

- Committed `0ba9044` ("make tmux session names match workmux worktree handles"):
  `.config/scripts/tmux-sessionizer` (worktree-aware naming) +
  `.config/scripts/workmux-sync-prefix` (new). `logs/` left untracked per
  repo convention; this timeline copied to the main checkout before merge
  since merge removes the worktree.
- Rebased onto local `master`: already up to date, no conflicts.
