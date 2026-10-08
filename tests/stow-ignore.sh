#!/usr/bin/env bash
# Focused test: .stow-local-ignore must keep non-config entries out of $HOME.
# Dry-runs stow to a temp target (simulation mode: no filesystem changes)
# and asserts ignored top-level names never appear in the link plan.
# Run: ./tests/stow-ignore.sh
# Env: STOW_DIR_OVERRIDE to test a different stow dir (negative control).
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STOWDIR="${STOW_DIR_OVERRIDE:-$ROOT}"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

command -v stow >/dev/null 2>&1 || { fail_ "missing dependency: stow"; exit 1; }

TGT=$(mktemp -d)
trap 'rm -rf "$TGT"' EXIT
# NOTE: stow -v prints the action log to stderr.
plan=$(stow -n -v -d "$STOWDIR" -t "$TGT" . 2>&1 >/dev/null \
  | sed -n 's/^LINK: \([^ ]*\).*/\1/p') || fail_ "stow dry-run failed"

MUST_LINK=".bashrc .config .tmux.conf"
MUST_IGNORE="audio.sh essential.sh essential_remote.sh fix_kde_drive.sh \
ibm_fonts.sh remove_default.sh rsync_kaggle.sh sync_daemon.sh tablet.sh \
tablet-revert.sh logs wallpapers tests tpu-commands tpu-tasks ubuntu-tasks \
fedora-tasks touchcursor-linux .workmux .workmux.yaml .git .gitignore"

leaked=""
for name in $MUST_IGNORE; do
  if grep -qxF "$name" <<<"$plan"; then leaked="$leaked $name"; fi
done
if [[ -z $leaked ]]; then pass "ignored entries absent from link plan";
else fail_ "would be stowed despite ignore:$leaked"; fi

missing=""
for name in $MUST_LINK; do
  grep -qxF "$name" <<<"$plan" || missing="$missing $name"
done
if [[ -z $missing ]]; then pass "intended dotfiles present in link plan";
else fail_ "missing from link plan:$missing"; fi

exit "$fail"
