-- Port of telescope's builtin/__lsp.lua `list_or_jump`: ask all clients, merge,
-- (references: drop the current line), jump with show_document if exactly one,
-- otherwise show the results in mini.pick.
local function lsp_jump(action, title, extra)
	return function()
		local bufnr = vim.api.nvim_get_current_buf()
		local winnr = vim.api.nvim_get_current_win()
		local curr_filepath = vim.api.nvim_buf_get_name(bufnr)

		local params = function(client)
			local p = vim.lsp.util.make_position_params(winnr, client.offset_encoding)
			if extra then
				p = vim.tbl_extend("force", p, extra)
			end
			return p
		end

		vim.lsp.buf_request_all(bufnr, action, params, function(results_per_client)
			local items = {}
			local first_encoding
			local errors = {}

			for client_id, result_or_error in pairs(results_per_client) do
				local err, result = result_or_error.err, result_or_error.result
				if err then
					errors[client_id] = err
				elseif result ~= nil then
					local locations = {}
					if not vim.islist(result) then
						vim.list_extend(locations, { result })
					else
						vim.list_extend(locations, result)
					end
					local offset_encoding = vim.lsp.get_client_by_id(client_id).offset_encoding
					if not vim.tbl_isempty(result) then
						first_encoding = offset_encoding
					end
					vim.list_extend(items, vim.lsp.util.locations_to_items(locations, offset_encoding))
				end
			end

			for _, err in pairs(errors) do
				vim.notify(action .. " : " .. err.message, vim.log.levels.ERROR)
			end

			if action == "textDocument/references" then
				local lnum = vim.api.nvim_win_get_cursor(winnr)[1]
				items = vim.tbl_filter(function(v)
					return not (v.filename == curr_filepath and v.lnum == lnum)
				end, items)
			end

			if vim.tbl_isempty(items) then
				vim.notify(string.format("No %s found", title), vim.log.levels.INFO)
				return
			end

			if #items == 1 then
				vim.lsp.util.show_document(items[1].user_data, first_encoding, { reuse_win = false })
			else
				local pick_items = vim.tbl_map(function(it)
					return {
						text = string.format("%s:%d:%d: %s", vim.fn.fnamemodify(it.filename, ":."), it.lnum, it.col, vim.trim(it.text or "")),
						path = it.filename,
						lnum = it.lnum,
						col = it.col,
						user_data = it.user_data,
					}
				end, items)
				MiniPick.start({
					source = {
						name = title,
						items = pick_items,
						choose = function(item)
							local win = MiniPick.get_picker_state().windows.target
							if win and vim.api.nvim_win_is_valid(win) then
								vim.api.nvim_set_current_win(win)
							end
							vim.lsp.util.show_document(item.user_data, first_encoding, { reuse_win = false })
						end,
					},
				})
			end
		end)
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func)
			vim.keymap.set("n", keys, func, { buffer = event.buf })
		end

		local diagnostics_qf_open = false



		map("gd", lsp_jump("textDocument/definition", "LSP Definitions"))
		map("gr", lsp_jump("textDocument/references", "LSP References", { context = { includeDeclaration = true } }))
		map("gI", lsp_jump("textDocument/implementation", "LSP Implementations"))
		map("gy", lsp_jump("textDocument/typeDefinition", "LSP Type Definitions"))
		map("gs", function() MiniExtra.pickers.lsp({ scope = "document_symbol" }) end)
		map("gS", function() MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" }) end)
		map("cd", vim.lsp.buf.rename)
		map("g.", vim.lsp.buf.code_action)
		map("K", vim.lsp.buf.hover)
		map("gD", vim.lsp.buf.declaration)
		map("<leader>f", function()
			require("conform").format({ lsp_fallback = true })
		end)

		vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help)

		-- native LSP completion
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = false })
		end
		vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { buffer = event.buf })
	end,
})


vim.api.nvim_create_autocmd('LspDetach', {
	group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
	callback = function(event2)
		vim.lsp.buf.clear_references()
		-- vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
	end,
})

local servers = {
	-- pyrefly = {
	-- 	init_options = {
	-- 		displayTypeErrors = "force-off",
	-- 	},
	-- },
	ty = {
		settings = {
			ty = {
				diagnosticMode = 'off',
			}
		}
	},
	ruff = {},
	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				workspace = {
					checkThirdParty = false,
					library = {
						"${3rd}/luv/library",
						unpack(vim.api.nvim_get_runtime_file("", true)),
					},
				},
			},
		},
	},
}
require("mason").setup()

local ensure_installed = vim.tbl_keys(servers or {})

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

require("mason-lspconfig").setup({
	automatic_enable = true
})

for server_name, config in pairs(servers) do
	vim.lsp.config(server_name, config)
end

-- stop servers from registering inotify file watchers (exhausts fs.inotify.max_user_instances)
vim.lsp.config("*", {
	capabilities = {
		workspace = { didChangeWatchedFiles = { dynamicRegistration = false } },
	},
})



-- vespa lsp
local schemals_config = {
	    cmd = { "java", "-jar", "/usr/local/bin/vls.jar" },
	    filetypes = { "sd" },
    },

    vim.lsp.enable("schemals")
vim.lsp.config("schemals", schemals_config)

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "ruff", "black" },
		javascript = { { "prettierd", "prettier" } },
	},
})

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = false,
	signs = false,
	underline = false,
	loclist = { open = false },
	float = { border = 'rounded', source = 'if_many' },
})

vim.keymap.set('n', '[d', function()
	vim.diagnostic.goto_prev({ float = true })
end, { desc = 'Go to previous diagnostic and show float' })

vim.keymap.set('n', ']d', function()
	vim.diagnostic.goto_next({ float = true })
end, { desc = 'Go to next diagnostic and show float' })

local opening_qf = false

local function set_buf_diagnostics_qf(open)
	local items = vim.diagnostic.toqflist(vim.diagnostic.get(0))
	local cur = vim.fn.getqflist({ title = 0 })
	local action = cur.title == 'Diagnostics' and 'r' or ' '
	vim.fn.setqflist({}, action, { title = 'Diagnostics', items = items })
	if open then
		opening_qf = true
		vim.cmd('copen')
		opening_qf = false
	end
end

vim.api.nvim_create_autocmd({ 'DiagnosticChanged', 'BufEnter' }, {
	callback = function()
		if opening_qf or vim.bo.buftype ~= '' then return end
		local qflist = vim.fn.getqflist({ winid = 0, title = 0 })
		local is_diag_open = qflist.winid ~= 0 and vim.api.nvim_win_is_valid(qflist.winid) and qflist.title == 'Diagnostics'
		if is_diag_open then
			set_buf_diagnostics_qf(false)
		end
	end,
})

local function toggle_diagnostics_qf()
	local qflist = vim.fn.getqflist({ winid = 0, title = 0 })
	local is_open = qflist.winid ~= 0 and vim.api.nvim_win_is_valid(qflist.winid)
	if is_open and qflist.title == 'Diagnostics' then
		vim.cmd('cclose')
	else
		set_buf_diagnostics_qf(true)
	end
end

vim.keymap.set('n', '<leader>qd', toggle_diagnostics_qf, { desc = 'Toggle diagnostics in quickfix list' })
vim.keymap.set('n', '<leader>dl', toggle_diagnostics_qf, { desc = 'Toggle diagnostics in quickfix list' })
