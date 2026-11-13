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
local isnt_installed = function(lang)
	return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
end
local to_install = vim.tbl_filter(isnt_installed, ensure_installed)
if #to_install > 0 then
	require("nvim-treesitter").install(to_install)
end

-- Enable Neovim's built-in treesitter highlighting for all filetypes of these languages.
-- (main branch no longer does `highlight = { enable = true }` for you.)
local filetypes = {}
for _, lang in ipairs(ensure_installed) do
	for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
		table.insert(filetypes, ft)
	end
end
local ts_group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = ts_group,
	pattern = filetypes,
	callback = function(ev)
		pcall(vim.treesitter.start, ev.buf)
	end,
})
