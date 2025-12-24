return {
    {'rebelot/kanagawa.nvim',
    config = function()
        require("kanagawa").setup({
                transparant = true,
                theme = "kanagawa-wave"
            })
        vim.cmd('colorscheme kanagawa-wave')
        -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        -- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
        -- vim.api.nvim_set_hl(0, "TroubleNormal", { link = "Normal"})
        -- vim.api.nvim_set_hl(0, "TroubleNormalNC", { link = "NormalNC" })
    end
}
}
