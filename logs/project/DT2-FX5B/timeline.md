# DT2-FX5B timeline — Ctrl+Enter / Ctrl+S passthrough (aven, monstar, tmux)

## 2026-10-08 — investigation + fix + verification (agent: muse)

### Problem (from task)
Ctrl+Enter and Ctrl+S do not work inside tmux. Both are the submit keys of
aven TUI's add-task composer (`Ctrl-Enter / Ctrl-s create from any field`,
per aven binary strings). Chain: outer terminal (Ghostty / monstar
v1.0.1, libghostty-based, always reports `TERM=xterm-ghostty`) -> tmux 3.6a
-> aven TUI (crossterm, Kitty keyboard via `PushKeyboardEnhancementFlags`).

### Evidence collected (all observed in-session, inside tmux)
1. Fresh tmux pane has `ixon` ON (`stop = ^S`):
   `/tmp/stty-tmux.txt` from a real pane showed `ixon`, so a bare 0x13
   (Ctrl+S) is eaten by the tty line discipline (XOFF) before any
   non-raw-mode app sees it. (aven itself uses raw mode so its own TUI is
   protected, but the shell prompt freezes and non-raw apps lose Ctrl+S.)
2. `man tmux` (3.6a): `extended-keys` is the **xterm modifyOtherKeys**
   equivalent, NOT Kitty. App negotiation is `CSI > 4;1 m` (mode 1).
   Kitty pushes (`CSI > flags u`, `CSI ? u`) from a pane get **no reply**
   (probed, got `<NO-REPLY>`). So aven's Kitty-only negotiation is silently
   ignored by tmux.
3. Byte-level recorder in a scratch pane (`send-keys`, `od -An -tx1`):
   - server `extended-keys on`, no app negotiation: `C-Enter` -> `0d`
     (plain CR, indistinguishable from Enter). This was the Ctrl+Enter bug.
   - app negotiated modifyOtherKeys (`CSI > 4;1 m`), format `csi-u`:
     `C-Enter` -> `1b 5b 31 33 3b 35 75` (`CSI 13;5u`).
   - server `extended-keys always`, NO app negotiation, format `csi-u`:
     `C-Enter` -> `CSI 13;5u`, `Enter` -> `0d`, `ZZZ` -> unchanged.
     `always` forces mode 1, so Kitty-only apps (aven) get extended keys
     without negotiating.
4. aven E2E with throwaway DBs (`aven --db /tmp/....sqlite tui
   --add-task-only`, submit via `send-keys`, check `aven --db ... list`):
   - `C-Enter` submitted the composer -> task created (repeated 2x).
   - `C-s` submitted the composer with pane `ixon` off -> task created.
   - Control: pane `ixon` on + `C-s` ALSO submitted, because aven puts the
     tty in raw mode (clears IXON itself). So the `stty -ixon` fix matters
     for the shell prompt / non-raw apps, not for aven's own TUI.
5. `~/.tmux.conf -> ~/dotfiles2/.tmux.conf` and `~/.bashrc ->
   ~/dotfiles2/.bashrc` (main checkout, master, has uncommitted edits);
   this branch `dt2-fx5b` was behind main. `~/.config/monstar/config ->
   ../../dotfiles2/.config/monstar/config` (untracked in main).
   Ghostty `~/.config/ghostty/config` is unmanaged (not in repo); its
   `keybind = ctrl+enter=csi:27;5;13~` sends the xterm modifyOtherKeys
   encoding, which tmux parses — left as-is (helps, does not hurt).
   monstar v1.0.1 has no keybind support — nothing to configure there.

### Root causes
- Ctrl+Enter: tmux `extended-keys on` only extends keys for apps that
  negotiate xterm modifyOtherKeys; aven negotiates Kitty only (ignored by
  tmux), so Ctrl+Enter arrived as plain CR.
- Ctrl+S: `ixon` flow control eats 0x13 at the shell prompt / in non-raw
  apps (classic "C-s freezes terminal").

### Changes (in branch `dt2-fx5b`)
- `.tmux.conf`: reconciled with main's live version (workmux binds,
  `allow-passthrough on`, `terminal-features xterm*:extkeys:RGB`,
  `update-environment TERM/TERM_PROGRAM`) and set
  `set -s extended-keys always` + `set -s extended-keys-format csi-u`
  (was: `on` / unset-default-`xterm`). Regression scope: mode 1 only
  changes keys with no standard representation; Enter/letters verified
  unchanged. Revert to `on` if a legacy app misbehaves.
- `.bashrc`: `stty -ixon 2>/dev/null || true` for interactive shells.
- Live tmux server was also switched to `always`/`csi-u` at runtime for
  testing (via `tmux source-file ./​.tmux.conf`); it now matches the
  committed file. Pre-existing env note: `~/.tmux/plugins/tpm` is not
  installed, so the trailing `run tpm` line errors 127 on source — same
  before this change.

### Verification (observed outputs, this session)
- `bash -n .bashrc` -> syntax OK; `tmux source-file ./.tmux.conf` -> clean.
- Fresh pane `stty -a`: `ixon` before, `-ixon` after the fix line.
- C-Enter E2E (sourced-file state): composer submitted, temp DB gained
  `DTF-F8F2 title="final verify ctrl-enter"`, window exited.
- Full `git diff --stat`: `.bashrc +6`, `.tmux.conf +20/-2`.

### Residual risks / next steps for human or next agent
1. **Real keypress from Ghostty/monstar not yet tested** — sandbox could
   only inject keys via `tmux send-keys`. Please press Ctrl+Enter / Ctrl+S
   in `aven tui` inside tmux in the real terminal to confirm the outer leg
   (esp. monstar's default Ctrl+Enter encoding, which is unconfigurable in
   v1.0.1). If monstar sends plain CR, no tmux setting can fix it there.
2. After merge to master, new panes get `stty -ixon` automatically; running
   shells need `stty -ixon` once or a re-login. tmux server already runs
   the fixed options, no restart needed (already sourced).
3. Deliberately NOT changed: Ghostty keybind override, monstar config
   (nothing to set), aven binary (not in repo).
