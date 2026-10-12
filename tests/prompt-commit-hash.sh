#!/usr/bin/env bash
# Focused test: dispatch prompts must tell agents never to commit unless
# specified by the user, and must not attach commit hash instructions.
# Static check over both prompt templates (workmux-open, copy-prompt).
# Run: ./tests/prompt-commit-hash.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

for prog in workmux-open copy-prompt; do
  f="$ROOT/.config/aven/commands/$prog"
  [[ -f $f ]] || { fail_ "template missing: $f"; continue; }
  if grep -qi 'commit hash' "$f"; then
    fail_ "$prog prompt must not attach commit hash instruction"
  else
    pass "$prog prompt does not mention commit hash"
  fi
  if grep -q 'Never commit unless specified by the user' "$f"; then
    pass "$prog prompt tells agents never to commit unless specified by the user"
  else
    fail_ "$prog prompt must tell agents never to commit unless specified by the user"
  fi
  if grep -q 'aven note' "$f"; then
    pass "$prog prompt includes aven note instruction"
  else
    fail_ "$prog prompt must include aven note instruction"
  fi
  if bash -n "$f" 2>/dev/null; then
    pass "$prog passes bash -n"
  else
    fail_ "$prog fails bash -n"
  fi
done

tpl="$ROOT/.config/aven/prompts/yy.md"
if [[ -f $tpl ]]; then
  pass "prompt template yy.md exists"
  if grep -qi 'commit hash' "$tpl"; then
    fail_ "yy.md must not attach commit hash instruction"
  else
    pass "yy.md does not mention commit hash"
  fi
  if grep -q 'Never commit unless specified by the user' "$tpl"; then
    pass "yy.md tells agents never to commit unless specified by the user"
  else
    fail_ "yy.md must tell agents never to commit unless specified by the user"
  fi
  if grep -q 'aven note' "$tpl"; then
    pass "yy.md includes aven note instruction"
  else
    fail_ "yy.md must include aven note instruction"
  fi
else
  fail_ "prompt template yy.md missing: $tpl"
fi

exit "$fail"
