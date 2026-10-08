# Timeline — DT2-X7V5: clear dotfiles scripts (stow ignore)

Task: DT2-X7V5 (`clear dotfiles scripts`, status active, project dotfiles2).
Ask: scripts that's not part of config should be put on `.stow` ignore
(i.e. `.stow-local-ignore`).

## 2026-10-08 — investigation (agent: muse)

- Marked task `active` in aven.
- Repo stows as a single package from its root (`stow .`, target `$HOME`):
  wanted links are `.bashrc`, `.tmux.conf`, `.config`; everything else at
  the top level that is not ignored becomes a stray `$HOME` link.
- Live strays in `$HOME` (all `-> dotfiles2/...`, i.e. created by stow from
  the main checkout): `audio.sh`, `essential_remote.sh`, `fix_kde_drive.sh`,
  `ibm_fonts.sh`, `monstar.sh`, `rsync_kaggle.sh`, `sync_daemon.sh`,
  `tablet.sh`, `tablet-revert.sh`, plus `logs`, `wallpapers`, `.workmux.yaml`.
  (`essential.sh` / `remove_default.sh` are correctly absent — already ignored.)
- Simulated from this worktree
  (`stow -n -v --target=/tmp/fakehome .`, GNU Stow 2.4.1): with the old
  ignore file it plans exactly the 3 wanted links plus 13 unwanted ones
  (9 root scripts, `logs`, `wallpapers`, `.workmux`, `.workmux.yaml`).
  `/.git` matching the worktree `.git` file and bare `essential.sh`-style
  segment patterns behave as expected per `Stow.pm` (`/`-less lines match
  basenames, lines with `/` match `(^|/)(PATTERN)(/|$)` against `/path`).
- Scope call: fixed all 13 strays, not just the 9 scripts — `logs`,
  `wallpapers`, `.workmux`, `.workmux.yaml` are the same bug (non-config
  top-level entries), consistent with the existing precedent of ignoring
  `tpu-*`, `ubuntu-tasks`, `fedora-tasks`, `touchcursor-linux`.
- Convention: root script basenames appended bare (like the existing
  `remove_default.sh` / `essential.sh` lines); dirs and dotfiles with a
  leading slash (like `/touchcursor-linux`, `/.git`). Verified all 9 script
  basenames are unique repo-wide (only dups are `gcloud.sh`/`zed.sh` inside
  the already-ignored task dirs), so bare segment patterns cannot shadow
  anything under `.config/scripts`.
- `.config/desktop.json` carries no wallpapers path; nothing references
  `~/wallpapers` or `~/logs`, so ignoring them breaks no config.

## 2026-10-08 — implementation (agent: muse)

- `.stow-local-ignore`: appended `audio.sh`, `essential_remote.sh`,
  `fix_kde_drive.sh`, `ibm_fonts.sh`, `monstar.sh`, `rsync_kaggle.sh`,
  `sync_daemon.sh`, `tablet.sh`, `tablet-revert.sh`, `/logs`, `/wallpapers`,
  `/.workmux`, `/.workmux.yaml`. Existing lines untouched.
- Validation: `stow -n -v --target=<fresh>` now plans only `.bashrc`,
  `.config`, `.tmux.conf`; second probe with a pre-existing
  `<target>/.config` (forces stow to descend instead of folding) confirms
  `.config/scripts/*.sh` and `.config/aven/commands/*` are still linked —
  the new bare-`.sh` patterns do not shadow nested config scripts.
- Changes left uncommitted in worktree `dt2-x7v5` for review/merge.

## Activation (for user — NOT done)

- Merge this worktree to master, then re-stow from the main checkout
  (`cd ~/dotfiles2 && stow -R .` with your usual target flags) so the
  now-ignored strays (`~/audio.sh`, `~/logs`, …) are unlinked. Do NOT
  re-stow from this worktree — that would repoint `$HOME` links here.
- `stow -R` only removes symlinks it owns; real files are untouched. Live
  `~/logs -> dotfiles2/logs` etc. disappear on restow, nothing else changes.

## Notes for next agent

- If the user adds another root-level helper script later, add its basename
  to `.stow-local-ignore` (a generic "all root `*.sh`" pattern was
  considered and rejected to stay with the file's explicit-list convention).
- `logs/` timelines stay tracked in git (this file included); only
  `.workmux/` is git-excluded (main checkout `.git/info/exclude`).
