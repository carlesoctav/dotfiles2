vim.b.slime_cell_delimiter = "#%%"
vim.keymap.set("n", "<c-c><c-c>", "<Plug>SlimeCellsSendAndGoToNext")
vim.keymap.set("n", "<c-c><c-Down>", "<Plug>SlimeCellsNext")
vim.keymap.set("n", "<c-c><c-Up>", "<Plug>SlimeCellsPrev")
vim.opt_local.makeprg = "ruff check --output-format github %"
vim.opt_local.errorformat = "%*[^:]::%f:%l:%c: %m"

-- gK: run 'keywordprg' (pydoc) on the full dotted name (e.g. torch.linalg.svd) in a vertical split
vim.keymap.set("n", "gK", function()
  local old = vim.bo.iskeyword
  vim.opt_local.iskeyword:append(".")
  local name = vim.fn.expand("<cword>")
  vim.bo.iskeyword = old
  if name == "" then return end

  local res = vim.system({ "sh", "-c", vim.bo.keywordprg .. " " .. vim.fn.shellescape(name) }, { text = true, env = { PAGER = "cat" } }):wait()
  local out = vim.split(vim.trim((res.stdout or "") .. (res.stderr or "")), "\n")

  vim.cmd("vertical new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = "nofile", "wipe", false
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
end, { buffer = true, desc = "keywordprg on dotted name in vsplit" })
