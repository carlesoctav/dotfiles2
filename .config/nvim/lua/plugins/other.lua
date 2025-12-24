return {
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup()
			require("mini.statusline").setup()
			require("mini.jump").setup()
			require("mini.bufremove").setup()
			require("mini.splitjoin").setup(
				{
					mappings = {
					    toggle = '<leader>tj',
					    split = '',
					    join = '',
					},
				}
			)
			vim.keymap.set("n", "<C-q>", function()
				require("mini.bufremove").delete(0, false)
			end)
		end,
	},
	{
		"LunarVim/bigfile.nvim",
		opts = {}
	},
    {"tpope/vim-sleuth"},
    {"tpope/vim-surround"}
}

