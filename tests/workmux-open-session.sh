#!/usr/bin/env bash
# Regression test (DT2-1GP2): workmux-open derives parent session using
# sessionizer logic, ensures the session exists, and handles focus cleanly:
# - Inside tmux: invokes workmux add followed by workmux open with --parent-session.
# - Outside tmux: invokes workmux add with -b to suppress stray switch-client,
#   skips workmux open, and attaches via tmux attach.
#
# Hermetic: stub workmux/tmux, scratch DB.
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

cat >"$STUB/tmux" <<EOF
#!/usr/bin/env bash
echo "tmux \$*" >>"$TDIR/calls.log"
case "\${1:-}" in
  new-session)
    # Record created session name (arg after -ds)
    shift
    while ((\$#)); do
      if [[ \$1 == -ds ]]; then touch "$TDIR/sess_\$2"; break; fi
      shift
    done
    ;;
  has-session)
    # Check if session was created
    sess=\${3:-}
    if [[ -f "$TDIR/sess_\$sess" ]]; then exit 0; else exit 1; fi
    ;;
  list-windows) printf '@1\t probe\n' ;;
  *) exit 0 ;;
esac
EOF

cat >"$STUB/workmux" <<EOF
#!/usr/bin/env bash
echo "workmux \$*" >>"$TDIR/calls.log"
case "\${1:-}" in
  path) exit 1 ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$STUB/tmux" "$STUB/workmux"

for tool in wl-copy xclip xsel pbcopy; do
  printf '#!/usr/bin/env bash\nexit 1\n' >"$STUB/$tool"
  chmod +x "$STUB/$tool"
done

make_ctx() { # $1=db $2=task_id $3=task_ref $4=out
  jq -n --arg db "$1" --arg exe "$(command -v aven)" \
    --arg id "$2" --arg ref "$3" --arg cwd "$TDIR" \
    '{version: 1, invocation: {db_path: $db, aven_exe: $exe, cwd: $cwd},
      targeting: {targets: [{id: $id, ref: $ref}]},
      selection: {primary: {project: {key: ""}}}}' >"$4"
}

DB="$TDIR/db.sqlite"
aven --db "$DB" add "zz probe task" --status todo >/dev/null
TASK_ID=$(aven --db "$DB" list --json | jq -r '.[0].id')
TASK_REF=$(aven --db "$DB" list --json | jq -r '.[0].ref')
CTX="$TDIR/context.json"
make_ctx "$DB" "$TASK_ID" "$TASK_REF" "$CTX"

run_prog() { # $1=tmux-env-value (empty means unset) $2=stdin-name
  local tmux_env=$1 name=$2
  : >"$TDIR/calls.log"
  if [[ -z $tmux_env ]]; then
    printf '%s\n' "$name" | env -u TMUX PATH="$STUB:$HOME/.local/bin:/usr/bin:/bin" \
      AVEN_COMMAND_CONTEXT="$CTX" "$PROG" 2>&1
  else
    printf '%s\n' "$name" | TMUX="$tmux_env" PATH="$STUB:$HOME/.local/bin:/usr/bin:/bin" \
      AVEN_COMMAND_CONTEXT="$CTX" "$PROG" 2>&1
  fi
}

# Case 1: Inside tmux
out=$(run_prog dummy-stub zz-probe-inside); code=$?
((code == 0)) && pass "inside tmux: exit 0" || fail_ "inside tmux: exit=$code out='$out'"
grep -q 'tmux new-session -ds ' "$TDIR/calls.log" \
  && pass "inside tmux: ensured session exists" \
  || fail_ "inside tmux: missing new-session; calls: $(cat "$TDIR/calls.log")"
grep -q 'workmux add zz-probe-inside --open-if-exists --mode window --parent-session ' "$TDIR/calls.log" \
  && pass "inside tmux: workmux add with parent session" \
  || fail_ "inside tmux: workmux add missing; calls: $(cat "$TDIR/calls.log")"
grep -q 'workmux open zz-probe-inside --mode window --parent-session ' "$TDIR/calls.log" \
  && pass "inside tmux: workmux open invoked for focus" \
  || fail_ "inside tmux: workmux open missing; calls: $(cat "$TDIR/calls.log")"

# Case 2: Outside tmux
out=$(run_prog '' zz-probe-outside); code=$?
((code == 0)) && pass "outside tmux: exit 0" || fail_ "outside tmux: exit=$code out='$out'"
grep -q 'workmux add zz-probe-outside --open-if-exists -b --mode window --parent-session ' "$TDIR/calls.log" \
  && pass "outside tmux: workmux add has -b flag" \
  || fail_ "outside tmux: workmux add missing -b; calls: $(cat "$TDIR/calls.log")"
grep -q 'workmux open' "$TDIR/calls.log" \
  && fail_ "outside tmux: workmux open should NOT be called; calls: $(cat "$TDIR/calls.log")" \
  || pass "outside tmux: workmux open skipped (no stray switch-client)"
grep -q 'tmux attach -t ' "$TDIR/calls.log" \
  && pass "outside tmux: finale attach preserved" \
  || fail_ "outside tmux: finale attach missing; calls: $(cat "$TDIR/calls.log")"

exit "$fail"
