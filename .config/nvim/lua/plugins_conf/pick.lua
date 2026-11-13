-- mini.pick replacements for the old telescope keymaps (<leader>s prefix)
local map = function(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end

local show_with_icons = function(buf_id, items, query)
	return MiniPick.default_show(buf_id, items, query, { show_icons = true })
end

map("<C-p>", '<Cmd>Pick files tool="git"<CR>', "Git files")
map("<leader>sf", function()
	MiniPick.builtin.cli(
		{ command = { "rg", "--files", "--hidden", "-g", "!.git", "--color=never" } },
		{ source = { name = "Files (hidden)", show = show_with_icons } }
	)
end, "Files")
map("<leader>sh", "<Cmd>Pick help<CR>", "Help tags")
map("<leader>ss", "<Cmd>Pick resume<CR>", "Resume picker")
map("<leader>sg", "<Cmd>Pick grep_live<CR>", "Grep live")
map("<leader>sw", '<Cmd>Pick grep pattern="<cword>"<CR>', "Grep word")
map("<leader>?", "<Cmd>Pick oldfiles<CR>", "Old files")
map("<leader><space>", "<Cmd>Pick buffers<CR>", "Buffers")
map("<leader>sd", '<Cmd>Pick diagnostic scope="all"<CR>', "Diagnostics")
map("<leader>sq", function()
	local last = vim.fn.getqflist({ nr = "$" }).nr
	if last == 0 then
		vim.notify("No quickfix lists in history", vim.log.levels.INFO)
		return
	end
	local cur = vim.fn.getqflist({ nr = 0 }).nr
	local items = {}
	for i = last, 1, -1 do
		local info = vim.fn.getqflist({ nr = i, title = 0, size = 0 })
		local title = info.title ~= "" and info.title or "[No Title]"
		local mark = i == cur and ">" or " "
		table.insert(items, {
			text = string.format("%s %2d │ %s (%d)", mark, i, title, info.size),
			nr = i,
		})
	end
	MiniPick.start({
		source = {
			name = "Quickfix history",
			items = items,
			preview = function(buf_id, item)
				local qf_items = vim.fn.getqflist({ nr = item.nr, items = 0 }).items or {}
				local lines = {}
				for _, q in ipairs(qf_items) do
					local name = q.bufnr > 0 and vim.fn.fnamemodify(vim.api.nvim_buf_get_name(q.bufnr), ":.") or ""
					table.insert(lines, string.format("%s:%d:%d: %s", name, q.lnum, q.col, vim.trim(q.text)))
				end
				if #lines == 0 then lines = { "[Empty]" } end
				vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
			end,
			choose = function(item)
				vim.schedule(function()
					vim.cmd(string.format("chistory %d | copen", item.nr))
				end)
			end,
		},
	})
end, "Quickfix history")
map("<leader>/", '<Cmd>Pick buf_lines scope="current"<CR>', "Search in buffer")

-- <leader>sv: search files inside .venv (or $VIRTUAL_ENV)
map("<leader>sv", function()
	local venv = vim.env.VIRTUAL_ENV
	if not venv or vim.uv.fs_stat(venv) == nil then
		venv = vim.fn.getcwd() .. "/.venv"
	end
	if vim.uv.fs_stat(venv) == nil then
		vim.notify("No .venv or $VIRTUAL_ENV found", vim.log.levels.WARN)
		return
	end
	MiniPick.builtin.cli(
		{ command = { "rg", "--files", "--hidden", "--no-ignore", "--color=never" } },
		{ source = { name = "Files (.venv)", cwd = venv, show = show_with_icons } }
	)
end, "Search files in .venv")

-- mini.visits: pinned file stack ("pin" label)
map("<leader>ma", function()
	MiniVisits.add_label("pin")
	vim.notify("Pinned " .. vim.fn.expand("%:t"))
end, "Pin file")
map("<leader>md", function()
	MiniVisits.remove_label("pin")
	vim.notify("Unpinned " .. vim.fn.expand("%:t"))
end, "Unpin file")
map("<leader>mn", function()
	MiniVisits.iterate_paths("forward", nil, { filter = "pin", wrap = true })
end, "Next pinned file")
map("<leader>mp", function()
	MiniVisits.iterate_paths("backward", nil, { filter = "pin", wrap = true })
end, "Previous pinned file")
map("<leader>sm", function()
	local unpin = function()
		local matches = MiniPick.get_picker_matches()
		local cur = matches and matches.current
		if not cur then return end
		local cwd = vim.fn.getcwd()
		MiniVisits.remove_label("pin", vim.fs.normalize(cwd .. "/" .. cur), cwd)
		local items = vim.tbl_filter(function(it)
			return it ~= cur
		end, MiniPick.get_picker_items())
		MiniPick.set_picker_items(items)
	end
	MiniExtra.pickers.visit_paths({ filter = "pin" }, {
		source = { name = "Pinned files" },
		mappings = { unpin = { char = "<C-d>", func = unpin } },
	})
end, "Pinned files")

-- <leader>si: search all files including gitignored & hidden (excluding .git)
map("<leader>si", function()
	MiniPick.builtin.cli(
		{ command = { "rg", "--files", "--hidden", "--no-ignore", "-g", "!.git", "--color=never" } },
		{ source = { name = "Files (ignored + hidden)", show = show_with_icons } }
	)
end, "Search ignored/hidden files")
