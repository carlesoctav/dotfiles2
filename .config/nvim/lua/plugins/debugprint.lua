return {
    {
        "andrewferrier/debugprint.nvim",
        event = "VeryLazy",
        dependencies = {
            "echasnovski/mini.nvim",         -- Optional: Needed for line highlighting (full mini.nvim plugin)
        },
        version = "*",
        opts = {
            custom_print_statements = {
                jax_debug = {
                    statement = "jax.debug.print(%s)",
                    -- Optionally, set other options like `commented = false`
                },
            },
            keymaps = {
                normal = {
                    plain_below = "<leader>dp",
                    plain_above = "<leader>dP",
                    variable_below = "<leader>dv",
                    variable_above = "<leader>dV",
                    variable_below_alwaysprompt = "",
                    variable_above_alwaysprompt = "",
                    surround_plain = "<leader>dsp",
                    surround_variable = "<leader>dsv",
                    surround_variable_alwaysprompt = "",
                    textobj_below = "<leader>do",
                    textobj_above = "<leader>dO",
                    textobj_surround = "<leader>dso",
                    toggle_comment_debug_prints = "<leader>dto",
                    delete_debug_prints = "<leader>dtd",
                    jax_debug_below = "<leader>dj", -- new keymap for jax.debug.print()
                },
                insert = {
                    plain = "<C-G>p",
                    variable = "<C-G>v",
                },
                visual = {
                    variable_below = "<leader>dv",
                    variable_above = "<leader>dV",
                },
            },
        }
    }
}
