-- LSP without mason: reuse the language servers the main config already
-- installed (~/.local/share/nvim/mason/bin). Each server only enables when
-- its binary is executable, so a missing binary degrades to no-LSP rather
-- than a startup error.

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
        local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end
        map("gd", require("telescope.builtin").lsp_definitions, "go to definition")
        map("gr", require("telescope.builtin").lsp_references, "go to references")
        map("gI", require("telescope.builtin").lsp_implementations, "go to implementation")
        map("gy", require("telescope.builtin").lsp_type_definitions, "go to type definition")
        map("gs", require("telescope.builtin").lsp_document_symbols, "document symbols")
        map("gS", require("telescope.builtin").lsp_dynamic_workspace_symbols, "workspace symbols")
        map("cd", vim.lsp.buf.rename, "rename")
        map("g.", vim.lsp.buf.code_action, "code action")
        map("K", vim.lsp.buf.hover, "hover")
        map("gD", vim.lsp.buf.declaration, "go to declaration")
        map("<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, "format buffer")
        vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = event.buf })
    end,
})

vim.api.nvim_create_autocmd("LspDetach", {
    group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
    callback = function()
        vim.lsp.buf.clear_references()
    end,
})

local mason_bin = vim.fn.expand("~/.local/share/nvim/mason/bin")
local servers = {
    ruff = {
        cmd = { mason_bin .. "/ruff", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
    },
    ty = {
        cmd = { mason_bin .. "/ty", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        settings = {
            ty = {
                diagnosticMode = "off",
            },
        },
    },
    lua_ls = {
        cmd = { mason_bin .. "/lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".git" },
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

for name, config in pairs(servers) do
    vim.lsp.config(name, config)
    if vim.fn.executable(config.cmd[1]) == 1 then
        vim.lsp.enable(name)
    end
end

-- diagnostics: quiet, quickfix-driven (mirrors the main config)
vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    signs = false,
    underline = false,
    loclist = { open = false },
    float = { border = "rounded", source = "if_many" },
})

vim.keymap.set("n", "[d", function()
    vim.diagnostic.goto_prev({ float = true })
end, { desc = "Go to previous diagnostic and show float" })

vim.keymap.set("n", "]d", function()
    vim.diagnostic.goto_next({ float = true })
end, { desc = "Go to next diagnostic and show float" })

-- walk the quickfix list (where gd/gr land) without leaving your code
local function qf_step(cmd)
    return function()
        if #vim.fn.getqflist() == 0 then
            vim.notify("quickfix list is empty", vim.log.levels.INFO)
            return
        end
        if not pcall(vim.cmd, cmd) then
            vim.notify("no further quickfix entries", vim.log.levels.INFO)
        end
    end
end
vim.keymap.set("n", "[q", qf_step("cprevious"), { desc = "previous quickfix entry" })
vim.keymap.set("n", "]q", qf_step("cnext"), { desc = "next quickfix entry" })

vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function()
        vim.diagnostic.setqflist({ open = false })
    end,
})

vim.keymap.set("n", "<leader>dl", function()
    local qflist = vim.fn.getqflist({ winid = 0, title = 0 })
    local is_open = qflist.winid ~= 0 and vim.api.nvim_win_is_valid(qflist.winid)
    if is_open and qflist.title == "Diagnostics" then
        vim.cmd("cclose")
    else
        vim.diagnostic.setqflist({ open = true })
    end
end, { desc = "Toggle diagnostics in quickfix list" })
