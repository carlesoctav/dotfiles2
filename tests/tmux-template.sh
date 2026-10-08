#!/usr/bin/env bash
# Focused test: every new tmux session must spawn template windows 1-4.
# Uses an isolated tmux server (-L) sourcing a config file; never touches
# the user's live server. Run: ./tests/tmux-template.sh
# Env: TMUX_CONF_OVERRIDE to test a different config (negative control).
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CONF="${TMUX_CONF_OVERRIDE:-$ROOT/.tmux.conf}"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

command -v tmux >/dev/null 2>&1 || { fail_ "missing dependency: tmux"; exit 1; }
[[ -f $CONF ]] || { fail_ "config not found: $CONF"; exit 1; }

SOCK="tmpltest$$"
tmux -L "$SOCK" kill-server 2>/dev/null || true
trap 'tmux -L "$SOCK" kill-server 2>/dev/null' EXIT
tmux -L "$SOCK" -f "$CONF" new-session -d -s t1 -x 80 -y 24 2>/dev/null || true
tmux -L "$SOCK" has-session -t t1 2>/dev/null \
  && pass "test session created" || { fail_ "test session missing"; exit "$fail"; }

count=$(tmux -L "$SOCK" list-windows -t t1 2>/dev/null | wc -l)
((count == 4)) && pass "4 windows spawned" || fail_ "windows=$count, want 4"

idx=$(tmux -L "$SOCK" list-windows -t t1 -F '#{window_index}' 2>/dev/null | tr '\n' ' ')
[[ $idx == "1 2 3 4 " ]] && pass "indices are 1 2 3 4" || fail_ "indices='$idx'"

exit "$fail"
