#!/usr/bin/env bash
# Focused test for the `jupyter` notebook config: launcher must exec nvim
# with NVIM_APPNAME=jupyter, config must be vim.pack-only (no lazy.nvim),
# and every lua file must parse. Hermetic: stub nvim, no plugins touched.
# Run: ./tests/jupyter.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG="$ROOT/.config/scripts/jupyter"
CFG="$ROOT/.config/jupyter"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

[[ -x $PROG ]] || { fail_ "program missing/not executable: $PROG"; exit 1; }
[[ -f $CFG/init.lua ]] || { fail_ "config missing: $CFG/init.lua"; exit 1; }

# 1. Launcher sets NVIM_APPNAME=jupyter, forwards args, propagates exit.
TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT
STUB="$TDIR/bin"; mkdir -p "$STUB"
printf '#!/usr/bin/env bash\necho "appname:$NVIM_APPNAME args:$*" >>"%s/calls.log"\nexit 7\n' "$TDIR" >"$STUB/nvim"
chmod +x "$STUB/nvim"
PATH="$STUB:/usr/bin:/bin" "$PROG" foo.ipynb -- bar >/dev/null 2>&1; code=$?
if ((code == 7)) && grep -q '^appname:jupyter args:foo.ipynb -- bar$' "$TDIR/calls.log" 2>/dev/null; then
  pass "launcher sets NVIM_APPNAME=jupyter, forwards args, exit 7"
else
  fail_ "launcher: exit=$code calls='$(cat "$TDIR/calls.log" 2>/dev/null)'"
fi

# 2. Required config files present.
missing=""
for f in init.lua lua/options.lua lua/remap.lua lua/packages.lua lua/treesitter.lua \
    lua/lsp.lua lua/jupyter.lua after/queries/python/textobjects.scm; do
  [[ -f $CFG/$f ]] || missing="$missing $f"
done
[[ -z $missing ]] && pass "config files present" || fail_ "missing files:$missing"

# 3. vim.pack-only: no lazy.nvim references; pack list declares the set.
if grep -rq "lazy" "$CFG" --include='*.lua'; then
  fail_ "config references lazy (must be vim.pack-only)"
else
  pass "no lazy references"
fi
for repo in molten-nvim jupytext.nvim otter.nvim nvim-treesitter \
    nvim-treesitter-textobjects mini.nvim gruvbox.nvim; do
  grep -q "$repo" "$CFG/lua/packages.lua" || fail_ "packages.lua missing $repo"
done
if grep -q "vim.pack.add" "$CFG/lua/packages.lua"; then
  pass "vim.pack.add declares plugin set"
else
  fail_ "vim.pack.add missing from packages.lua"
fi

# 4. Every lua file parses (loadfile compiles without executing).
if command -v nvim >/dev/null 2>&1; then
  bad=""
  while IFS= read -r f; do
    nvim --headless --clean -c "lua assert(loadfile([==[$f]==]))" -c "qa!" \
      >/dev/null 2>&1 || bad="$bad $f"
  done < <(find "$CFG" -name '*.lua')
  [[ -z $bad ]] && pass "all lua files parse" || fail_ "parse errors in:$bad"
else
  pass "nvim absent, parse check skipped"
fi

exit "$fail"
