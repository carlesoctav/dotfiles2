#!/usr/bin/env bash
# Focused test for .config/aven/commands/sessionizer (z f).
# The command must behave exactly like shell Ctrl+F: delegate to
# tmux-sessionizer. Hermetic: stub binaries, no tmux session touched.
# Run: ./tests/sessionizer.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG="$ROOT/.config/aven/commands/sessionizer"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

[[ -x $PROG ]] || fail_ "program missing/not executable: $PROG"
((fail)) && exit 1

# 1. Missing deps -> exit 2 (empty PATH, absolute bash so the outer
# shell can still resolve the interpreter).
if PATH=/nonexistent-dir /usr/bin/bash "$PROG" >/dev/null 2>&1; then
  fail_ "missing deps should exit nonzero"
else
  code=$?; ((code == 2)) && pass "missing deps exits 2" || fail_ "missing deps exit=$code, want 2"
fi

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT
STUB="$TDIR/bin"; mkdir -p "$STUB"
for tool in tmux fzf; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB/$tool"
  chmod +x "$STUB/$tool"
done

# 2. Delegates to tmux-sessionizer with args, propagates exit status.
printf '#!/usr/bin/env bash\necho "args:$*" >>"%s/calls.log"\nexit 7\n' "$TDIR" >"$STUB/tmux-sessionizer"
chmod +x "$STUB/tmux-sessionizer"
PATH="$STUB:/usr/bin:/bin" "$PROG" foo bar >/dev/null 2>&1; code=$?
if ((code == 7)) && grep -q '^args:foo bar$' "$TDIR/calls.log" 2>/dev/null; then
  pass "delegates args, propagates exit 7"
else
  fail_ "delegation: exit=$code calls='$(cat "$TDIR/calls.log" 2>/dev/null)'"
fi

# 3. Exit 0 passes through (fzf cancel / session jump both succeed).
printf '#!/usr/bin/env bash\nexit 0\n' >"$STUB/tmux-sessionizer"
rm -f "$TDIR/calls.log"
PATH="$STUB:/usr/bin:/bin" "$PROG" >/dev/null 2>&1; code=$?
((code == 0)) && pass "exit 0 passes through" || fail_ "exit=$code, want 0"

exit "$fail"
