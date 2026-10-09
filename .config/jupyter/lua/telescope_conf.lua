-- Fuzzy finder: telescope (+ plenary) with the ui-select dropdown.
-- Same keys as the main config. The main-only diffview git mappings are
-- omitted (no diffview/fugitive in this config).
require("telescope").setup({
    defaults = {
        mappings = {
            i = {
                ["<C-u>"] = false,
                ["<C-d>"] = false,
            },
        },
    },
    extensions = {
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
        },
    },
})

require("telescope").load_extension("ui-select")
vim.keymap.set("n", "<C-p>", require("telescope.builtin").git_files)
vim.keymap.set("n", "<leader>sf", function()
    require("telescope.builtin").find_files({ hidden = true })
end)
vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags)
vim.keymap.set("n", "<leader>ss", require("telescope.builtin").builtin)
vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep)
vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string)
vim.keymap.set("n", "<leader>?", require("telescope.builtin").oldfiles)
vim.keymap.set("n", "<leader><space>", require("telescope.builtin").buffers)
vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics)
vim.keymap.set("n", "<leader>/", function()
    require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
    }))
end, { desc = "[/] Fuzzily search in current buffer" })
