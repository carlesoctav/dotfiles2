#!/usr/bin/env bash
# Regression test (DT2-1GP2): workmux-open must not leave unrelated tmux
# clients behind in the worktree's session.
#
# Root cause: workmux focuses with bare `switch-client` (no -c). Without TMUX
# context (aven runs outside tmux) tmux drags an arbitrary attached client
# across sessions instead of the invoking one. The script must snapshot
# clients before workmux runs and switch every unrelated mover back.
#
# Hermetic: stub workmux/tmux, scratch DB. The workmux stub simulates the
# stray switch by rewriting the stub tmux's client table mid-run.
# Run: ./tests/workmux-open-restore-clients.sh
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

# Stub tmux: client table lives in $TDIR/clients (name<TAB>session per line).
# list-clients prints it; switch-client applies the move AND logs, so the
# test observes both the restore call and its effect.
cat >"$STUB/tmux" <<EOF
#!/usr/bin/env bash
echo "tmux \$*" >>"$TDIR/calls.log"
case "\${1:-}" in
  display-message) printf 'proj\n' ;;
  list-clients) cat "$TDIR/clients" ;;
  switch-client)
    cname=''; dest=''
    while ((\$#)); do
      case "\$1" in
        -c) cname=\$2; shift 2 ;;
        -t) dest=\${2#=}; shift 2 ;;
        *) shift ;;
      esac
    done
    awk -F'\t' -v c="\$cname" -v d="\$dest" 'BEGIN{OFS="\t"} \$1==c{\$2=d} {print}' \
      "$TDIR/clients" >"$TDIR/clients.new"
    mv "$TDIR/clients.new" "$TDIR/clients"
    ;;
  *) exit 0 ;;
esac
EOF
# Stub workmux: log invocations; `add` simulates workmux's stray bare
# switch-client by dragging EVERY client into the parent session (worst case
# of the DT2-1GP2 bug: arbitrary victims, possibly more than one).
cat >"$STUB/workmux" <<EOF
#!/usr/bin/env bash
echo "workmux \$*" >>"$TDIR/calls.log"
case "\${1:-}" in
  add)
    awk -F'\t' 'BEGIN{OFS="\t"} {\$2="proj"; print}' "$TDIR/clients" >"$TDIR/clients.new"
    mv "$TDIR/clients.new" "$TDIR/clients"
    ;;
  path) exit 1 ;;
esac
exit 0
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
aven --db "$DB" add "zz restore probe task" --status todo >/dev/null
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

# Case 1: inside tmux — the invoking session's client may follow, the
# unrelated one must be switched back.
printf '/dev/pts/10\tproj\n/dev/pts/11\tother\n' >"$TDIR/clients"
out=$(run_prog dummy-stub zz-probe-inside); code=$?
((code == 0)) && pass "inside tmux: exit 0" || fail_ "inside tmux: exit=$code out='$out'"
grep -q 'switch-client -c /dev/pts/11 -t =other' "$TDIR/calls.log" \
  && pass "inside tmux: unrelated client restored" \
  || fail_ "inside tmux: no restore call; calls: $(cat "$TDIR/calls.log")"
grep -q 'switch-client -c /dev/pts/10' "$TDIR/calls.log" \
  && fail_ "inside tmux: invoking-session client must be left alone" \
  || pass "inside tmux: invoking-session client untouched"
grep -q $'^/dev/pts/11\tother$' "$TDIR/clients" \
  && pass "inside tmux: client table shows unrelated back on other" \
  || fail_ "inside tmux: table wrong: $(cat "$TDIR/clients")"

# Case 2: outside tmux (how aven runs it) — no client is the invoker, so
# every moved client must be restored.
printf '/dev/pts/10\tplainA\n/dev/pts/11\tplainB\n' >"$TDIR/clients"
out=$(run_prog '' zz-probe-outside); code=$?
((code == 0)) && pass "outside tmux: exit 0" || fail_ "outside tmux: exit=$code out='$out'"
grep -q 'switch-client -c /dev/pts/11 -t =plainB' "$TDIR/calls.log" \
  && pass "outside tmux: unrelated client restored" \
  || fail_ "outside tmux: no restore call; calls: $(cat "$TDIR/calls.log")"
grep -q 'switch-client -c /dev/pts/10 -t =plainA' "$TDIR/calls.log" \
  && pass "outside tmux: second moved client restored too (no invoker)" \
  || fail_ "outside tmux: expected restore of pts/10; calls: $(cat "$TDIR/calls.log")"
grep -q 'tmux attach -t ' "$TDIR/calls.log" \
  && pass "outside tmux: finale attach preserved" \
  || fail_ "outside tmux: finale attach missing; calls: $(cat "$TDIR/calls.log")"

exit "$fail"
