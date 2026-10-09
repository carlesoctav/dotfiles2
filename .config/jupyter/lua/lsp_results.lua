-- LSP go-to results in one reused vertical split (the "results pane").
-- gd/gr/gI/gy/gs/gS land here instead of the quickfix list: the pane is
-- created once (like Ctrl-W v), reused on every later jump, and the cursor
-- never leaves the source window. <CR> on a result line jumps there (in the
-- source window, pane stays open for the next jump); q closes the pane.
local M = {}

local results_buf = nil
local results_win = nil
local src_win = nil -- source window of the latest request
local entries = {} -- jump targets, one per line: { uri, lnum0, col0 }

local function jump_target_win()
    if
        src_win
        and vim.api.nvim_win_is_valid(src_win)
        and vim.api.nvim_win_get_buf(src_win) ~= results_buf
    then
        return src_win
    end
    local cur = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_buf(cur) ~= results_buf then
        return cur
    end
    vim.cmd("wincmd p")
    return vim.api.nvim_get_current_win()
end

local function jump_to(entry)
    local win = jump_target_win()
    vim.api.nvim_set_current_win(win)
    vim.lsp.util.show_document({
        uri = entry.uri,
        range = {
            start = { line = entry.lnum0, character = entry.col0 },
            ["end"] = { line = entry.lnum0, character = entry.col0 },
        },
    }, "utf-8", { focus = true })
end

local function ensure_buf()
    if results_buf and vim.api.nvim_buf_is_valid(results_buf) then
        return results_buf
    end
    results_buf = vim.api.nvim_create_buf(false, true)
    vim.bo[results_buf].buftype = "nofile"
    vim.bo[results_buf].bufhidden = "hide"
    vim.bo[results_buf].buflisted = false
    vim.bo[results_buf].swapfile = false
    vim.bo[results_buf].filetype = "lsp-results"
    vim.keymap.set("n", "<CR>", function()
        local entry = entries[vim.api.nvim_win_get_cursor(0)[1]]
        if entry then
            jump_to(entry)
        end
    end, { buffer = results_buf, silent = true, desc = "jump to result" })
    vim.keymap.set("n", "q", function()
        if results_win and vim.api.nvim_win_is_valid(results_win) then
            vim.api.nvim_win_close(results_win, true)
        end
    end, { buffer = results_buf, silent = true, desc = "close results pane" })
    return results_buf
end

-- Show the pane, reusing the existing split when there is one.
local function show_pane(title, count)
    local buf = ensure_buf()
    if
        not (
            results_win
            and vim.api.nvim_win_is_valid(results_win)
            and vim.api.nvim_win_get_buf(results_win) == buf
        )
    then
        results_win = nil
        for _, w in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(w) == buf then
                results_win = w -- user moved the pane; adopt it
                break
            end
        end
        if not results_win then
            -- enter=false: cursor stays in the source window
            results_win = vim.api.nvim_open_win(buf, false, { split = "right", win = 0 })
            vim.api.nvim_win_set_width(results_win, math.max(40, math.floor(vim.o.columns * 0.4)))
            vim.wo[results_win].number = false
            vim.wo[results_win].relativenumber = false
            vim.wo[results_win].wrap = false
        end
    end
    vim.wo[results_win].winbar = " " .. title .. " (" .. count .. ")"
    return results_win
end

local function render(title, items)
    local buf = ensure_buf()
    entries = items
    local lines = {}
    for _, it in ipairs(items) do
        lines[#lines + 1] = it.text
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    show_pane(title, #items)
end

local function relpath(fname)
    return vim.fn.fnamemodify(fname, ":~:.")
end

local function line_text(uri, lnum0)
    local fname = vim.uri_to_fname(uri)
    local bufnr = vim.fn.bufnr(fname)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        return vim.api.nvim_buf_get_lines(bufnr, lnum0, lnum0 + 1, false)[1] or ""
    end
    local lines = vim.fn.readfile(fname)
    return lines[lnum0 + 1] or ""
end

local function loc_text(uri, lnum0, col0)
    local text = vim.trim(line_text(uri, lnum0))
    return string.format("%s:%d:%d: %s", relpath(vim.uri_to_fname(uri)), lnum0 + 1, col0 + 1, text)
end

-- Location | Location[] | LocationLink[] -> flat jump items (order kept).
local function convert_locations(result)
    local out = {}
    local list = result.uri ~= nil and { result } or result.targetUri ~= nil and { result } or result
    for _, loc in ipairs(list) do
        local uri = loc.uri or loc.targetUri
        local start = loc.range and loc.range.start or loc.targetSelectionRange.start
        local lnum0, col0 = start.line, start.character
        out[#out + 1] = { uri = uri, lnum0 = lnum0, col0 = col0, text = loc_text(uri, lnum0, col0) }
    end
    return out
end

local function kind_name(kind)
    return vim.lsp.protocol.SymbolKind[kind] or "?"
end

local function flatten_symbols(syms, uri, container, out)
    for _, s in ipairs(syms) do
        if s.location then -- SymbolInformation
            local start = s.location.range.start
            local name = (s.containerName and s.containerName .. " › " or "") .. s.name
            out[#out + 1] = {
                uri = s.location.uri,
                lnum0 = start.line,
                col0 = start.character,
                text = string.format(
                    "[%s] %s  (%s:%d)",
                    kind_name(s.kind),
                    name,
                    relpath(vim.uri_to_fname(s.location.uri)),
                    start.line + 1
                ),
            }
        else -- DocumentSymbol
            local start = s.selectionRange.start
            local name = (container and container .. " › " or "") .. s.name
            out[#out + 1] = {
                uri = uri,
                lnum0 = start.line,
                col0 = start.character,
                text = string.format("[%s] %s", kind_name(s.kind), name),
            }
            if s.children then
                flatten_symbols(s.children, uri, name, out)
            end
        end
    end
    return out
end

local function request(method, params, title, convert)
    -- Invoked from inside the results pane: step back to the source first.
    if
        results_buf
        and vim.api.nvim_get_current_buf() == results_buf
        and src_win
        and vim.api.nvim_win_is_valid(src_win)
    then
        vim.api.nvim_set_current_win(src_win)
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, method = method })
    if #clients == 0 then
        vim.notify(title .. ": no LSP client", vim.log.levels.WARN)
        return
    end
    src_win = vim.api.nvim_get_current_win()
    vim.lsp.buf_request_all(bufnr, method, params, function(responses)
        local items, seen = {}, {}
        for _, resp in pairs(responses) do
            if resp.result then
                for _, it in ipairs(convert(resp.result, bufnr) or {}) do
                    local key = it.uri .. ":" .. it.lnum0 .. ":" .. it.col0
                    if not seen[key] then -- several servers may answer: dedupe
                        seen[key] = true
                        items[#items + 1] = it
                    end
                end
            end
        end
        if #items == 0 then
            vim.notify(title .. ": no results", vim.log.levels.INFO)
            return
        end
        render(title, items)
    end)
end

local function pos_params()
    return vim.lsp.util.make_position_params(0, "utf-8")
end

function M.definition()
    request("textDocument/definition", pos_params(), "Definitions", convert_locations)
end

function M.references()
    local params = pos_params()
    params.context = { includeDeclaration = true }
    request("textDocument/references", params, "References", convert_locations)
end

function M.implementation()
    request("textDocument/implementation", pos_params(), "Implementations", convert_locations)
end

function M.type_definition()
    request("textDocument/typeDefinition", pos_params(), "Type definitions", convert_locations)
end

function M.document_symbols()
    request(
        "textDocument/documentSymbol",
        { textDocument = vim.lsp.util.make_text_document_params() },
        "Document symbols",
        function(result, bufnr)
            return flatten_symbols(result, vim.uri_from_bufnr(bufnr), nil, {})
        end
    )
end

function M.workspace_symbols()
    local query = vim.fn.expand("<cword>")
    if query == "" then
        query = vim.fn.input("Workspace symbols: ")
    end
    if query == "" then
        return
    end
    request("workspace/symbol", { query = query }, "Workspace symbols: " .. query, function(result, bufnr)
        return flatten_symbols(result, vim.uri_from_bufnr(bufnr), nil, {})
    end)
end

return M
