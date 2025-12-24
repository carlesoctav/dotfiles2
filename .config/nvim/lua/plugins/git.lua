return {
	{
		"lewis6991/gitsigns.nvim",
		config = function(opts)
			require('gitsigns').setup({
				sign_priority = 100,
				on_attach = function(bufnr)
					local gitsigns = require('gitsigns')
					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

				-- Navigation
				map('n', ']c', function()
					gitsigns.nav_hunk('next')
				end, { desc = 'Go to next git change' })

				map('n', '[c', function()
					gitsigns.nav_hunk('prev')
				end, { desc = 'Go to previous git change' })

				-- Diff actions
				map('n', 'do', gitsigns.preview_hunk_inline, { desc = 'Expand diff hunk' })
				map('n', 'dO', gitsigns.toggle_deleted, { desc = 'Toggle staged' })
				map('n', 'du', function()
					gitsigns.stage_hunk()
					gitsigns.nav_hunk('next')
				end, { desc = 'Stage and next' })
				map('n', 'dU', function()
					gitsigns.unstage_hunk()
					gitsigns.nav_hunk('next')
				end, { desc = 'Unstage and next' })
				map('n', 'dp', gitsigns.reset_hunk, { desc = 'Restore change' })

				-- Other mappings
				map('n', '<leader>th', function()
					gitsigns.setqflist('all')
				end)

				map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
				end
			})
		end
	},

	"tpope/vim-fugitive",
	{'akinsho/git-conflict.nvim', version = "*", config = true}

}
