-- jupyter: lean notebook config, opened with the `jupyter` shell command
-- (`NVIM_APPNAME=jupyter nvim`). State lives under ~/.local/share/jupyter,
-- separate from the main config. Plugins are managed by built-in vim.pack
-- (Neovim 0.12+), see lua/packages.lua.
--
-- First launch clones plugins into the pack dir. Treesitter parsers
-- install async in the background. Code execution routes to tmux
-- panes (colab repl, ipython, etc.) via vim-slime. Update later with `:PackUpdate`.

require("options")
require("remap")

-- Reuse the main config's Python env: jupyter_client,
-- ipykernel (kernels), jupytext (ipynb <-> py:percent conversion).
vim.g.python3_host_prog = vim.fn.expand("~/.config/nvim/.venv/bin/python")
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

require("packages")
require("treesitter")
require("telescope_conf")
require("image_conf")
require("lsp")
require("jupyter")
