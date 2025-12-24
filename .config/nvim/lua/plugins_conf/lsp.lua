vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func)
			vim.keymap.set("n", keys, func, { buffer = event.buf })
		end

		local diagnostics_qf_open = false



		map("gd", require("telescope.builtin").lsp_definitions)
		map("gr", require("telescope.builtin").lsp_references)
		map("gI", require("telescope.builtin").lsp_implementations)
		map("gy", require("telescope.builtin").lsp_type_definitions)
		map("gs", require("telescope.builtin").lsp_document_symbols)
		map("gS", require("telescope.builtin").lsp_dynamic_workspace_symbols)
		map("cd", vim.lsp.buf.rename)
		map("g.", vim.lsp.buf.code_action)
		map("K", vim.lsp.buf.hover)
		map("gD", vim.lsp.buf.declaration)
		map("<leader>f", function()
			require("conform").format({ lsp_fallback = true })
		end)

		vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help)
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
	pyrefly = {
		init_options = {
			displayTypeErrors = "on",
		},
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

vim.api.nvim_create_autocmd('DiagnosticChanged', {
	callback = function(args)
		vim.diagnostic.setloclist({ open = false })
		vim.diagnostic.setqflist({ open = false })
	end,
})


vim.keymap.set('n', '<leader>dq', function()
	local qflist = vim.fn.getqflist({ winid = 0 })
	local is_open = qflist.winid ~= 0 and vim.api.nvim_win_is_valid(qflist.winid)
	if is_open then
		vim.cmd('cclose')
	else
		vim.diagnostic.setqflist({ open = true })
	end
end, { desc = 'Toggle global diagnostics in quickfix list' })

vim.keymap.set('n', '<leader>dl', function()
	local loclist = vim.fn.getloclist(0, { title = 0, winid = 0 })
	local is_open = loclist.winid ~= 0 and vim.api.nvim_win_is_valid(loclist.winid)
	if is_open then
		vim.cmd('lclose')
	else
		vim.diagnostic.setloclist({ open = true })
	end
end, { desc = 'Toggle diagnostics in location list' })
