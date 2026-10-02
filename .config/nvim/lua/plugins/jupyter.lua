-- Jupyter notebooks: molten (run code) + jupytext (ipynb <-> py:percent) + otter (LSP in docs).
-- Python side lives in ~/.config/nvim/.venv (python3_host_prog in init.lua):
-- pynvim + jupyter_client (molten), ipykernel (the `nvim` kernel), jupytext (conversion).

local group = vim.api.nvim_create_augroup("Jupyter", { clear = true })

-- `# %%` cell helpers (jupytext py:percent buffers) -------------------------------
-- Markers are real `comment` nodes in the Python tree, so a `# %%` inside a
-- string/docstring is correctly ignored. Falls back to a plain line scan when
-- the parser is unavailable (same semantics, minus the string awareness).
local marker_query = nil
local function ts_marker_rows()
    if vim.bo.filetype ~= "python" then
        return nil
    end
    local ok, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok or parser == nil then
        return nil
    end
    if marker_query == nil then
        local qok, q = pcall(vim.treesitter.query.parse, "python", "(comment) @marker")
        if not qok then
            return nil
        end
        marker_query = q
    end
    local pok, trees = pcall(function()
        return parser:parse(true)
    end)
    if not pok or trees == nil or trees[1] == nil then
        return nil
    end
    local rows = {}
    for _, node in marker_query:iter_captures(trees[1]:root(), 0) do
        if vim.treesitter.get_node_text(node, 0):match("^# %%") then
            local row = node:range()
            rows[#rows + 1] = row + 1
        end
    end
    return rows
end

local function scan_marker_rows()
    local rows = {}
    for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if line:match("^# %%") then
            rows[#rows + 1] = i
        end
    end
    return rows
end

local function marker_rows()
    return ts_marker_rows() or scan_marker_rows()
end

local function current_cell()
    local markers = marker_rows()
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local last = vim.api.nvim_buf_line_count(0)
    local top = 1
    for _, m in ipairs(markers) do
        if m <= cur then
            top = m + 1
        else
            break
        end
    end
    local bottom = last
    for _, m in ipairs(markers) do
        if m >= top then
            bottom = m - 1
            break
        end
    end
    if top > last then
        top = last
    end
    if bottom < top then
        bottom = top
    end
    return top, bottom
end

local function run_cell()
    local top, bottom = current_cell()
    vim.fn.MoltenEvaluateRange(top, bottom)
end

local function run_cell_next()
    run_cell()
    local _, bottom = current_cell()
    local last = vim.api.nvim_buf_line_count(0)
    for _, m in ipairs(marker_rows()) do
        if m >= bottom then
            vim.api.nvim_win_set_cursor(0, { math.min(m + 1, last), 0 })
            return
        end
    end
end

local function run_cell_insert_below()
    run_cell()
    local _, bottom = current_cell()
    vim.api.nvim_buf_set_lines(0, bottom, bottom, false, { "# %%", "" })
    vim.api.nvim_win_set_cursor(0, { bottom + 2, 0 })
end

-- Jupyter-style molten keybinds, only in *.ipynb buffers --------------------------
vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
    group = group,
    pattern = "*.ipynb",
    callback = function(args)
        local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
        end
        -- the jupyter trio
        map("n", "<C-CR>", run_cell, "molten: run cell")
        map("n", "<S-CR>", run_cell_next, "molten: run cell and go to next")
        map("n", "<M-CR>", run_cell_insert_below, "molten: run cell and insert cell below")
        map("v", "<C-CR>", ":<C-u>MoltenEvaluateVisual<CR>gv", "molten: run selection")
        -- F-keys: plain sequences every terminal passes through, no protocol needed
        map("n", "<F5>", run_cell, "molten: run cell")
        map("n", "<S-F5>", run_cell_next, "molten: run cell and go to next")
        map("n", "<M-F5>", run_cell_insert_below, "molten: run cell and insert cell below")
        map("v", "<F5>", ":<C-u>MoltenEvaluateVisual<CR>gv", "molten: run selection")
        -- fallbacks (if the terminal eats the Enter chords) + essentials
        map("n", "<localleader>E", run_cell_next, "molten: run cell and go to next")
        map("v", "<localleader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", "molten: run selection")
        map("n", "<localleader>mi", ":MoltenInit<CR>", "molten: init kernel")
        map("n", "<localleader>rl", ":MoltenEvaluateLine<CR>", "molten: evaluate line")
        map("n", "<localleader>rr", ":MoltenReevaluateCell<CR>", "molten: re-evaluate cell")
        map("n", "<localleader>md", ":MoltenDelete<CR>", "molten: delete cell")
        map("n", "<localleader>oh", ":MoltenHideOutput<CR>", "molten: hide output")
        map("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>", "molten: show/enter output")
        map("n", "<localleader>mc", ":MoltenInterrupt<CR>", "molten: interrupt kernel")
        map("n", "<localleader>mr", ":MoltenRestart<CR>", "molten: restart kernel")
    end,
})

-- otter: LSP inside code blocks of markdown/quarto docs ---------------------------
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "markdown", "quarto" },
    callback = function()
        local ok, otter = pcall(require, "otter")
        if ok then
            pcall(otter.activate)
        end
    end,
})

return {
    {
        "benlubas/molten-nvim",
        version = "^1.0.0",
        build = ":UpdateRemotePlugins",
        init = function()
            vim.g.molten_output_win_max_height = 12
            vim.g.molten_virt_text_output = false
            vim.g.molten_auto_open_output = true
            vim.g.molten_output_virt_lines = true
            vim.g.molten_wrap_output = true
        end,
    },
    {
        "goerz/jupytext.nvim",
        version = "0.2.0",
        opts = {
            format = "py:percent",
            jupytext = vim.fn.expand("~/.config/nvim/.venv/bin/jupytext"),
        },
    },
    {
        "jmbuhr/otter.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {},
    },
}
