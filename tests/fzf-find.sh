#!/usr/bin/env bash
# Focused test for .config/aven/commands/fzf-find.
# Hermetic: uses a scratch aven database, never the user's real one.
# Run: ./tests/fzf-find.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG="$ROOT/.config/aven/commands/fzf-find"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

for dep in jq fzf aven; do
  command -v "$dep" >/dev/null 2>&1 || { fail_ "missing dependency: $dep"; }
done
[[ -x $PROG ]] || fail_ "program missing/not executable: $PROG"
((fail)) && exit 1

# 1. Missing context env -> nonzero exit, no stdout.
out=$(env -u AVEN_COMMAND_CONTEXT "$PROG" 2>/dev/null); code=$?
if ((code != 0)) && [[ -z $out ]]; then pass "missing context exits $code quietly";
else fail_ "missing context: exit=$code out='$out'"; fi

# 2. Unreadable context file -> exit 2.
AVEN_COMMAND_CONTEXT=/nonexistent-aven-context "$PROG" >/dev/null 2>&1; code=$?
((code == 2)) && pass "unreadable context exits 2" || fail_ "unreadable context exit=$code"

# 3. Wrong context version -> exit 2.
CTX_BAD=$(mktemp); printf '{"version":99}' >"$CTX_BAD"
AVEN_COMMAND_CONTEXT="$CTX_BAD" "$PROG" >/dev/null 2>&1; code=$?
((code == 2)) && pass "bad version exits 2" || fail_ "bad version exit=$code"

# 4. Happy path on scratch DB: filter selects alpha, shows its detail.
TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR" "$CTX_BAD" "$CTX" 2>/dev/null' EXIT
DB="$TDIR/db.sqlite"
aven --db "$DB" project create probe >/dev/null
aven --db "$DB" add "zz unique alpha task" --project probe --status todo >/dev/null
aven --db "$DB" add "zz unique beta task" --project probe --status todo >/dev/null
CTX=$(mktemp)
jq -n --arg db "$DB" --arg exe "$(command -v aven)" \
  '{version: 1, invocation: {db_path: $db, aven_exe: $exe},
    targeting: {targets: []}, selection: {primary: null}}' >"$CTX"
out=$(AVEN_COMMAND_CONTEXT="$CTX" FZF_DEFAULT_OPTS="--filter=alpha" "$PROG" 2>"$TDIR/err"); code=$?
if ((code == 0)) && grep -q "zz unique alpha task" <<<"$out" \
  && ! grep -q "zz unique beta task" <<<"$out"; then
  pass "filter selects alpha and shows its detail"
else
  fail_ "happy path: exit=$code out='$out'"
fi

# 5. No match -> quiet exit 0, empty stdout.
out=$(AVEN_COMMAND_CONTEXT="$CTX" FZF_DEFAULT_OPTS="--filter=nomatchzzz" "$PROG" 2>/dev/null); code=$?
if ((code == 0)) && [[ -z $out ]]; then pass "no match exits 0 quietly";
else fail_ "no match: exit=$code out='$out'"; fi

exit "$fail"
