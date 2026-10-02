return {
	{
		"lewis6991/gitsigns.nvim",
		config = function(opts)
			require('gitsigns').setup({
				sign_priority = 100,
				on_attach = function(bufnr)
					-- jupytext.nvim converts .ipynb buffers; gitsigns can't handle them
					if vim.api.nvim_buf_get_name(bufnr):match('%.ipynb$') then
						return false
					end
					local gitsigns = require('gitsigns')
					local function map(mode, l, r, opts)
						opts = opts or {}
						opts.buffer = bufnr
						vim.keymap.set(mode, l, r, opts)
					end

			-- Navigation
			map('n', ']c', function()
				if vim.api.nvim_win_get_option(0, "diff") then
					vim.cmd.normal({']c', bang = true})
				else
					gitsigns.nav_hunk('next')
				end
			end, { desc = 'Go to next git change' })

			map('n', '[c', function()
				if vim.api.nvim_win_get_option(0, "diff") then
					vim.cmd.normal({'[c', bang = true})
				else
					gitsigns.nav_hunk('prev')
				end
			end, { desc = 'Go to previous git change' })

			map('n', 'do', function()
				if vim.api.nvim_win_get_option(0, "diff") then
					vim.cmd.diffget()
				else
					gitsigns.preview_hunk_inline()
				end
			end, { desc = 'Expand diff hunk' })
			map('n', 'du', function() gitsigns.stage_hunk() end, { desc = 'Stage and next' })
			map('n', 'dp', function()
				if vim.api.nvim_win_get_option(0, "diff") then
					vim.cmd.diffput()
				else
					gitsigns.reset_hunk()
				end
			end, { desc = 'Restore change' })
				map('n', '<leader>th', function()
					local qflist = vim.fn.getqflist({ winid = 0, title = 0 })
					local is_open = qflist.winid ~= 0 and vim.api.nvim_win_is_valid(qflist.winid)
					if is_open and qflist.title == 'Hunks' then
						vim.cmd('cclose')
					else
						gitsigns.setqflist('all')
					end
				end, { desc = 'Toggle git changes in quickfix list' })

				map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
				end
			})
		end
	},

	"tpope/vim-fugitive",

    -- co — choose ours
    -- ct — choose theirs
    -- cb — choose both
    -- c0 — choose none
    -- ]x — move to previous conflict
    -- [x — move to next conflict
	{'akinsho/git-conflict.nvim', version = "*", config = true}

}
