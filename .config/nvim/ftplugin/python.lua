vim.b.slime_cell_delimiter = "#%%"
vim.keymap.set("n", "<c-c><c-c>", "<Plug>SlimeCellsSendAndGoToNext")
vim.keymap.set("n", "<c-c><c-Down>", "<Plug>SlimeCellsNext")
vim.keymap.set("n", "<c-c><c-Up>", "<Plug>SlimeCellsPrev")
vim.opt_local.makeprg = "ruff check --output-format github %"
vim.opt_local.errorformat = "%*[^:]::%f:%l:%c: %m"
