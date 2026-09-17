-- nvim-treesitter `main` branch (rewrite for Neovim 0.12+).
-- No `nvim-treesitter.configs`, no `ensure_installed`/`auto_install` in setup.
local ensure_installed = {
	"c",
	"cpp",
	"lua",
	"python",
	"rust",
	"vimdoc",
	"vim",
	"bash",
	"json",
	"go",
	"markdown",
	"markdown_inline",
}

require("nvim-treesitter").setup({
	-- parsers + queries go here (prepended to rtp)
	install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Install missing parsers async (no-op if already installed).
-- Use :TSInstall / :TSUpdate manually for updates.
local installed = require("nvim-treesitter").get_installed()
local not_installed = vim.tbl_filter(function(parser)
	return not vim.tbl_contains(installed, parser)
end, ensure_installed)
if #not_installed > 0 then
	require("nvim-treesitter").install(not_installed)
end

-- Enable Neovim's built-in treesitter highlighting for these filetypes.
-- (main branch no longer does `highlight = { enable = true }` for you.)
local ts_group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = ts_group,
	pattern = ensure_installed,
	callback = function()
		pcall(vim.treesitter.start)
	end,
})
