require("telescope").load_extension("rest")
vim.keymap.set("n", "<leader>rr", "<cmd>Rest run<CR>")
-- vim.keymap.set("n", "sr", require("telescope").extensions.rest.select_env)
