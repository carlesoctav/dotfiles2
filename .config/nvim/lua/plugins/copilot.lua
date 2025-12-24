return {
	{
		"olimorris/codecompanion.nvim",

		event = "VeryLazy",
		version = "v17.33.0", -- pin to this version to avoid breaking changes
		dependencies = {
			"github/copilot.vim",
		},
		init = function()
			vim.g.copilot_enabled = false
		end,
		config = function()
			require("codecompanion").setup({
				adapters = {
					acp = {
						opencode = function()
							return require("codecompanion.adapters").extend(create_opencode_acp_adapter())
						end,
					},
				},
				interactions = {
					chat = {
						adapter = {
							name = "copilot",
							model = "gpt-5.1-mini",
						},
						variables = {
							["buffer"] = {
								opts = {
									default_params = "pin", -- or 'watch'
								},
							},
						},
					},
				},
			})
			vim.keymap.set({ "x", "n" }, "<leader>aa", ":CodeCompanion #{buffer} ")
			vim.keymap.set({ "n", "x" }, "<leader>ad", ":CodeCompanionChat #{buffer} #{lsp} ")
			vim.keymap.set({ "x", "n" }, "<leader>ac", ":CodeCompanionChat #{buffer} ")
			vim.keymap.set("n", "<leader>ta", "<cmd>CodeCompanionChat Toggle<cr>")
		end,
	},
}

