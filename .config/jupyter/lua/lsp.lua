-- LSP without mason: reuse the language servers the main config already
-- installed (~/.local/share/nvim/mason/bin). Each server only enables when
-- its binary is executable, so a missing binary degrades to no-LSP rather
-- than a startup error.

-- Stock quickfix behavior for go-to results (setqflist + botright copen),
-- except the cursor never leaves the source window. Walk the list with
-- [q / ]q from where you stand.
local function qf_on_list(options)
    local src = vim.api.nvim_get_current_win()
    vim.fn.setqflist({}, " ", options)
    vim.cmd("botright copen")
    if vim.api.nvim_win_is_valid(src) then
        vim.api.nvim_set_current_win(src)
    end
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    callback = function(event)
        local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end
        map("gd", function()
            vim.lsp.buf.definition({ on_list = qf_on_list })
        end, "go to definition")
        map("gr", function()
            vim.lsp.buf.references(nil, { on_list = qf_on_list })
        end, "go to references")
        map("gI", function()
            vim.lsp.buf.implementation({ on_list = qf_on_list })
        end, "go to implementation")
        map("gy", function()
            vim.lsp.buf.type_definition({ on_list = qf_on_list })
        end, "go to type definition")
        map("gs", function()
            vim.lsp.buf.document_symbol({ on_list = qf_on_list })
        end, "document symbols")
        map("gS", function()
            local query = vim.fn.expand("<cword>")
            vim.lsp.buf.workspace_symbol(query ~= "" and query or nil, { on_list = qf_on_list })
        end, "workspace symbols")
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
