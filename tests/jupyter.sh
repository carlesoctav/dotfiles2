#!/usr/bin/env bash
# Focused test for the merged Jupyter notebook config in .config/nvim:
# launcher delegates to nvim, plugin spec is managed via lazy.nvim,
# cell runners route through vim-slime, and all lua files parse.
# Run: ./tests/jupyter.sh
set -u

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PROG="$ROOT/.config/scripts/jupyter"
CFG="$ROOT/.config/nvim"
fail=0
pass() { printf 'ok: %s\n' "$1"; }
fail_() { printf 'FAIL: %s\n' "$1"; fail=1; }

[[ -x $PROG ]] || { fail_ "program missing/not executable: $PROG"; exit 1; }
[[ -f $CFG/init.lua ]] || { fail_ "config missing: $CFG/init.lua"; exit 1; }

# 1. Launcher forwards args to nvim, propagates exit.
TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT
STUB="$TDIR/bin"; mkdir -p "$STUB"
printf '#!/usr/bin/env bash\necho "args:$*" >>"%s/calls.log"\nexit 7\n' "$TDIR" >"$STUB/nvim"
chmod +x "$STUB/nvim"
PATH="$STUB:/usr/bin:/bin" "$PROG" foo.ipynb -- bar >/dev/null 2>&1; code=$?
if ((code == 7)) && grep -q '^args:foo.ipynb -- bar$' "$TDIR/calls.log" 2>/dev/null; then
  pass "launcher delegates to nvim, forwards args, exit 7"
else
  fail_ "launcher: exit=$code calls='$(cat "$TDIR/calls.log" 2>/dev/null)'"
fi

# 2. Main nvim jupyter plugin spec present.
[[ -f $CFG/lua/plugins/jupyter.lua ]] && pass "plugins/jupyter.lua present in main nvim config" \
  || fail_ "missing $CFG/lua/plugins/jupyter.lua"

# 3. lazy.nvim spec declares vim-slime, jupytext, otter; no molten.
for repo in "jpalardy/vim-slime" "goerz/jupytext.nvim" "jmbuhr/otter.nvim"; do
  grep -q "$repo" "$CFG/lua/plugins/jupyter.lua" || fail_ "plugins/jupyter.lua missing $repo"
done
if ! grep -rq "molten" "$CFG/lua/plugins/jupyter.lua"; then
  pass "vim-slime, jupytext, otter declared in lazy.nvim spec, molten retired"
else
  fail_ "plugins/jupyter.lua still contains references to molten"
fi

# 4. vim-slime configured for tmux with bracketed paste and SlimeSend cell runner.
if grep -q 'vim.g.slime_target = "tmux"' "$CFG/lua/plugins/jupyter.lua" \
    && grep -q 'vim.g.slime_bracketed_paste = 1' "$CFG/lua/plugins/jupyter.lua" \
    && grep -q 'SlimeSend' "$CFG/lua/plugins/jupyter.lua"; then
  pass "vim-slime configured for tmux with bracketed paste and SlimeSend runner"
else
  fail_ "plugins/jupyter.lua must configure vim-slime for tmux and wire SlimeSend"
fi

# 5. Every lua file in .config/nvim parses cleanly.
if command -v nvim >/dev/null 2>&1; then
  bad=""
  while IFS= read -r f; do
    nvim --headless --clean -c "lua assert(loadfile([==[$f]==]))" -c "qa!" \
      >/dev/null 2>&1 || bad="$bad $f"
  done < <(find "$CFG/lua" -name '*.lua')
  [[ -z $bad ]] && pass "all lua files in main nvim config parse" || fail_ "parse errors in:$bad"
else
  pass "nvim absent, parse check skipped"
fi

exit "$fail"
