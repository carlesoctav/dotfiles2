#!/usr/bin/env bash
# Focused test: dispatch prompts must tell agents to include the commit
# hash/range in aven notes when their work produced new commit(s).
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
  if grep -q 'commit hash' "$f" && grep -q 'aven note' "$f"; then
    pass "$prog prompt mentions commit hash in aven-note instruction"
  else
    fail_ "$prog prompt must tell agents to put commit hash/range in notes when there are new commits"
  fi
  if bash -n "$f" 2>/dev/null; then
    pass "$prog passes bash -n"
  else
    fail_ "$prog fails bash -n"
  fi
done

exit "$fail"
