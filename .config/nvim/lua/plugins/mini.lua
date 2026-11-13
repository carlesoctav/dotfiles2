return {
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.extra").setup()
			local ai = require("mini.ai")
			ai.setup({
				n_lines = 500,
				custom_textobjects = {
					B = MiniExtra.gen_ai_spec.buffer(),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
					b = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
				},
			})
			require("mini.surround").setup()
			require("mini.pairs").setup()
			require("mini.statusline").setup()
			require("mini.jump").setup()
			local feed_pick = function(lhs)
				local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
				return function()
					vim.api.nvim_feedkeys(keys, "ni", false)
				end
			end
			local send_to_qf = function()
				local matches = MiniPick.get_picker_matches()
				if not matches then return end
				local items = #matches.marked > 0 and matches.marked or matches.all
				if #items == 0 then return end
				MiniPick.default_choose_marked(items)
				vim.fn.setqflist({}, "a", { title = "search" })
				return true
			end
			local copy_path = function()
				local matches = MiniPick.get_picker_matches()
				local cur = matches and matches.current
				if not cur then return end
				local path = type(cur) == "string" and cur:match("^[^%z]+") or (cur.path or cur.text)
				if not path or path == "" then return end
				vim.fn.setreg("+", path)
				vim.fn.setreg('"', path)
				vim.notify("Copied: " .. path)
				return true
			end
			require("mini.pick").setup({
				mappings = {
					page_down = { char = "<PageDown>", func = feed_pick("<C-f>") },
					page_up = { char = "<PageUp>", func = feed_pick("<C-b>") },
					send_to_qf = { char = "<C-q>", func = send_to_qf },
					copy_path = { char = "<C-y>", func = copy_path },
				},
			})
			require("mini.visits").setup()
			require("plugins_conf.pick")
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

