return {
    {
        'ellisonleao/gruvbox.nvim',
        config = function()
            require("gruvbox").setup({})
            vim.cmd('colorscheme gruvbox')
            -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
            -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
            -- vim.api.nvim_set_hl(0, "TroubleNormal", { link = "Normal"})
            -- vim.api.nvim_set_hl(0, "TroubleNormalNC", { link = "NormalNC" })
        end
    }
}
