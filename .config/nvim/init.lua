
require("options")
require("remap")

vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g._ts_force_sync_parsing = false


vim.filetype.add {
  extension = {
    profile = 'sd',
    sd = 'sd'
  }
}

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

if vim.g.vscode then
	vim.opt.rtp:prepend(lazypath)
	require("lazy").setup({
		spec = {
			{ import = "plugins.debugprint" },
			{ import = "plugins.others" },
			{ import = "plugins.treesitter" },
		},
	})
else
	vim.opt.rtp:prepend(lazypath)
	require("lazy").setup({
		spec = {
			{ import = "plugins" },
		},
	})

end
