#!/usr/bin/env bash
# Focused test: essential setup scripts must provision the agent toolchain.
# Static contract (hermetic, offline-safe): both scripts parse and contain
# the aven + workmux installers; ghostty (+Terra repo) must be present too.
# Run: ./tests/essential-tools.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

for script in essential.sh essential_remote.sh; do
  f="$ROOT/$script"
  [[ -f $f ]] || { fail_ "$script missing"; continue; }
  bash -n "$f" && pass "$script parses" || { fail_ "$script syntax error"; continue; }
  grep -q 'raine/aven/main/scripts/install' "$f" \
    && pass "$script installs aven" || fail_ "$script missing aven installer"
  grep -q 'raine/workmux/main/scripts/install' "$f" \
    && pass "$script installs workmux" || fail_ "$script missing workmux installer"
done

# Ghostty (+Terra, which only exists for it) belongs on the host script,
# never on remote.
grep -q 'terra-release' "$ROOT/essential.sh" \
  && pass "essential.sh enables Terra repo" || fail_ "essential.sh missing terra-release"
grep -qw 'ghostty' "$ROOT/essential.sh" \
  && pass "essential.sh installs ghostty" || fail_ "essential.sh missing ghostty"
grep -q 'terra-release' "$ROOT/essential_remote.sh" \
  && fail_ "essential_remote.sh must not enable Terra repo" || pass "essential_remote.sh skips Terra repo"
grep -qw 'ghostty' "$ROOT/essential_remote.sh" \
  && fail_ "essential_remote.sh must not install ghostty" || pass "essential_remote.sh skips ghostty"

exit "$fail"
