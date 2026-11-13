local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')
require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-u>"] = false,
				["<C-d>"] = false,
			},
		},
	},
	pickers = {
		git_commits = {
			mappings = {
				i = {
					["<C-d>"] = function() -- show diffview for the selected commit
						-- Open in diffview
						local entry = action_state.get_selected_entry()
						-- close Telescope window properly prior to switching windows
						actions.close(vim.api.nvim_get_current_buf())
						vim.cmd(("Gvdiffsplit %s^!"):format(entry.value))
					end,
				},
			},
		},
		git_bcommits = {
			mappings = {
				i = {
					["<C-d>"] = function() -- show diffview for the selected commit of current buffer
						-- Open in diffview
						local entry = action_state.get_selected_entry()
						-- close Telescope window properly prior to switching windows
						actions.close(vim.api.nvim_get_current_buf())
						vim.cmd(("Gvdiffsplit %s^!"):format(entry.value))
					end,
				},
			},
		},
		git_branches = {
			mappings = {
				i = {
					["<C-d>"] = function() -- show diffview comparing the selected branch with the current branch
						-- Open in diffview
						local entry = action_state.get_selected_entry()
						-- close Telescope window properly prior to switching windows
						actions.close(vim.api.nvim_get_current_buf())
						vim.cmd(("Gvdiffsplit %s^!"):format(entry.value))
					end,
				},
			},
		},
	},
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown {}
		}
	},
})

-- keymaps and ui-select moved to mini.pick (see plugins_conf/pick.lua)
