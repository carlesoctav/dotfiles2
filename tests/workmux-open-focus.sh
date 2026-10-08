#!/usr/bin/env bash
# Focused test: workmux-open must focus the worktree window by invoking
# `workmux open` after a successful `workmux add` (add alone leaves the
# client behind on first creation). Hermetic: stub workmux/tmux, scratch DB.
# Run: ./tests/workmux-open-focus.sh
# Env: PROG_OVERRIDE to test a different script copy (e.g. pre-fix HEAD).
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG="${PROG_OVERRIDE:-$ROOT/.config/aven/commands/workmux-open}"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

command -v jq >/dev/null 2>&1 || fail_ "missing dependency: jq"
command -v aven >/dev/null 2>&1 || fail_ "missing dependency: aven"
[[ -x $PROG ]] || fail_ "program missing/not executable: $PROG"
((fail)) && exit 1

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT
STUB="$TDIR/bin"; mkdir -p "$STUB"
touch "$TDIR/calls.log"

# Stub workmux: log invocations; add/open succeed, path fails (no prompt file).
cat >"$STUB/workmux" <<EOF
#!/usr/bin/env bash
echo "workmux \$*" >>"$TDIR/calls.log"
case "\${1:-}" in
  path) exit 1 ;;
  *) exit 0 ;;
esac
EOF
# Stub tmux: display-message prints nothing (no parent session), rest succeeds.
cat >"$STUB/tmux" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$STUB/workmux" "$STUB/tmux"
# Mask clipboard tools so the test never touches the real clipboard.
for tool in wl-copy xclip xsel pbcopy; do
  printf '#!/usr/bin/env bash\nexit 1\n' >"$STUB/$tool"
  chmod +x "$STUB/$tool"
done

# Scratch DB with one task; context points only at scratch state.
DB="$TDIR/db.sqlite"
aven --db "$DB" add "zz focus probe task" --status todo >/dev/null
TASK_ID=$(aven --db "$DB" list --json | jq -r '.[0].id')
TASK_REF=$(aven --db "$DB" list --json | jq -r '.[0].ref')
CTX="$TDIR/context.json"
jq -n --arg db "$DB" --arg exe "$(command -v aven)" \
  --arg id "$TASK_ID" --arg ref "$TASK_REF" --arg cwd "$TDIR" \
  '{version: 1, invocation: {db_path: $db, aven_exe: $exe, cwd: $cwd},
    targeting: {targets: [{id: $id, ref: $ref}]},
    selection: {primary: {project: {key: ""}}}}' >"$CTX"

# Run with TMUX set (stub) so the script skips the final attach branch.
out=$(printf 'zz-probe-win\n' | TMUX=dummy-stub PATH="$STUB:$HOME/.local/bin:/usr/bin:/bin" \
  AVEN_COMMAND_CONTEXT="$CTX" "$PROG" 2>&1); code=$?
((code == 0)) && pass "script exits 0" || fail_ "exit=$code out='$out'"

mapfile -t calls <"$TDIR/calls.log"
add_idx=-1; open_idx=-1
for i in "${!calls[@]}"; do
  [[ ${calls[$i]} == "workmux add "* ]] && add_idx=$i
  [[ ${calls[$i]} == "workmux open "* ]] && open_idx=$i
done
if ((add_idx >= 0)) && ((open_idx > add_idx)); then
  pass "workmux open invoked after successful add"
else
  fail_ "expected open after add; calls: ${calls[*]:-(none)}"
fi

exit "$fail"
