-- Plugin set for the notebook config, managed by built-in vim.pack.
-- Install dir: ~/.local/share/jupyter/site/pack/core/opt/ (per NVIM_APPNAME).
-- `load = true` sources each plugin's plugin/ files right away (treesitter's
-- :TSInstall commands and otter's plugin file need this); `confirm = false`
-- lets the first launch clone non-interactively. Pinned versions mirror the
-- main config's known-good set.

-- molten reads these when it initializes, so they must precede the pack load.
vim.g.molten_output_win_max_height = 12
vim.g.molten_virt_text_output = false
vim.g.molten_auto_open_output = true
vim.g.molten_output_virt_lines = true
vim.g.molten_wrap_output = true

local nvim_venv_bin = vim.fn.expand("~/.config/nvim/.venv/bin")

vim.pack.add({
    { src = "https://github.com/benlubas/molten-nvim", version = "v1.9.2" },
    { src = "https://github.com/goerz/jupytext.nvim", version = "v0.2.0" },
    "https://github.com/jmbuhr/otter.nvim",
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    "https://github.com/echasnovski/mini.nvim",
    "https://github.com/ellisonleao/gruvbox.nvim",
    "https://github.com/nvim-telescope/telescope.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/nvim-telescope/telescope-ui-select.nvim",
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
