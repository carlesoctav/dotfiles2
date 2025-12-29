require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"c",
		"cpp",
		"lua",
		"python",
		"rust",
		"vimdoc",
		"vim",
		"bash",
		"json",
	},
	sync_install = false,
	auto_install = true,
	ignore_install = {},
	modules = {},
	highlight = { enable = true },
	indent = { enable = false },
	textobjects = {
		move = {
			enable = true,
			set_jumps = true,
			goto_next_start = {
				["gj"] = "@function.outer",
				["]]"] = "@class.outer",
			},
			goto_next_end = {
				["gJ"] = "@function.outer",
				["]["] = "@class.outer",
			},
			goto_previous_start = {
				["gk"] = "@function.outer",
				["[["] = "@class.outer",
			},
			goto_previous_end = {
				["gK"] = "@function.outer",
				["[]"] = "@class.outer",
			},
		},
		select = {
			enable = true,
			lookahead = true,
			keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["ib"] = "@block.inner",
			},
		},
	},
})
