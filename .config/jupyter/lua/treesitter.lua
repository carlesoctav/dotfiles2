-- Treesitter (nvim-treesitter `main` branch). Parsers install into this
-- config's own data dir (~/.local/share/jupyter/site). Lean parser set for
-- notebooks; add more via :TSInstall.
local ensure_installed = {
    "python",
    "markdown",
    "markdown_inline",
    "lua",
    "vimdoc",
    "bash",
    "json",
}

require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Install missing parsers async (no-op if already installed).
local installed = require("nvim-treesitter").get_installed()
local not_installed = vim.tbl_filter(function(parser)
    return not vim.tbl_contains(installed, parser)
end, ensure_installed)
if #not_installed > 0 then
    require("nvim-treesitter").install(not_installed)
end

-- Enable Neovim's built-in treesitter highlighting for these filetypes.
local ts_group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = ts_group,
    pattern = ensure_installed,
    callback = function()
        pcall(vim.treesitter.start)
    end,
})

-- textobjects: functions/classes plus jupyter `# %%` cell markers
-- (query lives in after/queries/python/textobjects.scm).
require("nvim-treesitter-textobjects").setup({
    move = { set_jumps = true },
    select = { lookahead = true },
})

local move = require("nvim-treesitter-textobjects.move")
-- goto next start
vim.keymap.set({ "n", "x", "o" }, "gj", function()
    move.goto_next_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "]]", function()
    move.goto_next_start("@class.outer", "textobjects")
end)
-- goto next end
vim.keymap.set({ "n", "x", "o" }, "gJ", function()
    move.goto_next_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "][", function()
    move.goto_next_end("@class.outer", "textobjects")
end)
-- goto previous start
vim.keymap.set({ "n", "x", "o" }, "gk", function()
    move.goto_previous_start("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[[", function()
    move.goto_previous_start("@class.outer", "textobjects")
end)
-- goto previous end
vim.keymap.set({ "n", "x", "o" }, "gK", function()
    move.goto_previous_end("@function.outer", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[]", function()
    move.goto_previous_end("@class.outer", "textobjects")
end)
-- jupyter `# %%` cell markers
vim.keymap.set({ "n", "x", "o" }, "]j", function()
    move.goto_next_start("@cell.marker", "textobjects")
end)
vim.keymap.set({ "n", "x", "o" }, "[j", function()
    move.goto_previous_start("@cell.marker", "textobjects")
end)

local select = require("nvim-treesitter-textobjects.select")
vim.keymap.set({ "x", "o" }, "af", function()
    select.select_textobject("@function.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "if", function()
    select.select_textobject("@function.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ac", function()
    select.select_textobject("@class.outer", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ic", function()
    select.select_textobject("@class.inner", "textobjects")
end)
vim.keymap.set({ "x", "o" }, "ib", function()
    select.select_textobject("@block.inner", "textobjects")
end)
