-- Review comments for agy (<leader>cc to comment, <leader>cp to edit in vsplit, <leader>cy to yank all, <leader>cx to start new file)
local active_comment_files = {}

local function get_project_root()
	return vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
end

local function new_comment_file(root)
	local dir = root .. '/.comments'
	vim.fn.mkdir(dir, 'p')
	local path = string.format('%s/%s.xml', dir, os.date('%Y-%m-%d_%H-%M-%S'))
	active_comment_files[root] = path
	return path
end

local function get_comment_file()
	local root = get_project_root()
	if active_comment_files[root] then
		return active_comment_files[root]
	end
	local dir = root .. '/.comments'
	if vim.fn.isdirectory(dir) == 1 then
		local files = vim.fn.glob(dir .. '/*.xml', false, true)
		if #files > 0 then
			table.sort(files)
			active_comment_files[root] = files[#files]
			return active_comment_files[root]
		end
	end
	return new_comment_file(root)
end

local function get_comment_selection(is_visual)
	if not is_visual then
		local lnum = vim.api.nvim_win_get_cursor(0)[1]
		return vim.api.nvim_get_current_line(), lnum, lnum
	end
	local p1 = vim.fn.getpos('v')
	local p2 = vim.fn.getpos('.')
	local mode = vim.fn.mode()
	local lines = vim.fn.getregion(p1, p2, { type = mode })
	local start_line = math.min(p1[2], p2[2])
	local end_line = math.max(p1[2], p2[2])
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
	return table.concat(lines, '\n'), start_line, end_line
end

local function open_comment_float(on_submit)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = 'nofile'
	vim.bo[buf].bufhidden = 'wipe'
	vim.bo[buf].filetype = 'markdown'

	local width = math.min(72, math.max(40, math.floor(vim.o.columns * 0.6)))
	local height = 6
	local win = vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2) - 1,
		col = math.floor((vim.o.columns - width) / 2),
		style = 'minimal',
		border = 'rounded',
		title = ' Comment (<C-s> / <CR> save, q / <Esc> cancel) ',
		title_pos = 'center',
	})
	vim.wo[win].wrap = true

	local closed = false
	local function close()
		if closed then return end
		closed = true
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	local function submit()
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		local text = vim.trim(table.concat(lines, '\n'))
		close()
		if text ~= '' then
			on_submit(text)
		end
	end

	vim.keymap.set({ 'n', 'i' }, '<C-s>', function()
		vim.cmd('stopinsert')
		submit()
	end, { buffer = buf, nowait = true })
	vim.keymap.set('n', '<CR>', submit, { buffer = buf, nowait = true })
	vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true })
	vim.keymap.set('n', '<Esc>', close, { buffer = buf, nowait = true })

	vim.cmd('startinsert')
end

local function add_review_comment(is_visual)
	local quote, sline, eline = get_comment_selection(is_visual)
	local relpath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
	local line_attr = sline == eline and tostring(sline) or (sline .. '-' .. eline)

	open_comment_float(function(input)
		local block = string.format(
			'<comments>\n  <context file="%s" lines="%s">\n    <quote>%s</quote>\n  </context>\n  <comment from="carlesoctav">%s</comment>\n</comments>',
			relpath,
			line_attr,
			quote,
			input
		)
		local path = get_comment_file()
		local existing = ''
		local rf = io.open(path, 'r')
		if rf then
			existing = rf:read('*a')
			rf:close()
		end
		local wf = assert(io.open(path, 'w'))
		wf:write(existing ~= '' and (existing .. '\n\n' .. block) or block)
		wf:close()

		vim.fn.setreg('+', block)
		vim.notify('Saved comment to ' .. vim.fn.fnamemodify(path, ':.'))
	end)
end

vim.keymap.set('n', '<leader>cc', function() add_review_comment(false) end, { desc = 'Add review comment (line)' })
vim.keymap.set('x', '<leader>cc', function() add_review_comment(true) end, { desc = 'Add review comment (selection)' })

vim.keymap.set('n', '<leader>cp', function()
	vim.cmd('vsplit ' .. vim.fn.fnameescape(get_comment_file()))
end, { desc = 'Edit review comment file' })

vim.keymap.set('n', '<leader>cy', function()
	local path = get_comment_file()
	local f = io.open(path, 'r')
	local content = f and f:read('*a') or ''
	if f then f:close() end
	if content == '' then
		vim.notify('No review comments in ' .. vim.fn.fnamemodify(path, ':.'), vim.log.levels.INFO)
		return
	end
	vim.fn.setreg('+', content)
	vim.notify('Copied ' .. vim.fn.fnamemodify(path, ':.') .. ' to clipboard')
end, { desc = 'Yank all review comments' })

vim.keymap.set('n', '<leader>cx', function()
	local path = new_comment_file(get_project_root())
	vim.notify('New comment file: ' .. vim.fn.fnamemodify(path, ':.'))
end, { desc = 'New review comment file' })
