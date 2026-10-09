-- Plugin set for the notebook config, managed by built-in vim.pack.
-- Install dir: ~/.local/share/jupyter/site/pack/core/opt/ (per NVIM_APPNAME).
-- `load = true` sources each plugin's plugin/ files right away (treesitter's
-- :TSInstall commands and otter's plugin file need this); `confirm = false`
-- lets the first launch clone non-interactively. Pinned versions mirror the
-- main config's known-good set.

-- vim-slime: sends code directly to a tmux pane (colab repl, ipython, etc.).
vim.g.slime_target = "tmux"
vim.g.slime_bracketed_paste = 1
vim.g.slime_default_config = {
    socket_name = "default",
    target_pane = "{last}",
}
vim.g.slime_dont_ask_default = 1
vim.g.slime_no_mappings = 1

local nvim_venv_bin = vim.fn.expand("~/.config/nvim/.venv/bin")

vim.pack.add({
    "https://github.com/jpalardy/vim-slime",
    { src = "https://github.com/goerz/jupytext.nvim", version = "v0.2.0" },
    "https://github.com/jmbuhr/otter.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    "https://github.com/echasnovski/mini.nvim",
    "https://github.com/ellisonleao/gruvbox.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope-ui-select.nvim",
    "https://github.com/3rd/image.nvim",
}, { confirm = false, load = true })

vim.api.nvim_create_user_command("PackUpdate", function()
    vim.pack.update()
end, { desc = "Update vim.pack plugins" })

require("jupytext").setup({
    format = "py:percent",
    jupytext = nvim_venv_bin .. "/jupytext",
})

require("otter").setup({})

require("mini.ai").setup({ n_lines = 500 })
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.statusline").setup()
require("mini.jump").setup()
require("mini.bufremove").setup()
require("mini.splitjoin").setup({
    mappings = {
        toggle = "<leader>tj",
        split = "",
        join = "",
    },
})
require("mini.diff").setup()
vim.keymap.set("n", "<C-q>", function()
    require("mini.bufremove").delete(0, false)
end)

require("gruvbox").setup({})
vim.cmd("colorscheme gruvbox")
