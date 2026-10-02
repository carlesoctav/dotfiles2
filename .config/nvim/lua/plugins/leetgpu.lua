return {
    dir = "/home/carlesoctav/personal/leetgpu",
    name = "leetgpu.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        lang = "jax",
        accelerator = "TPU v5e",
        storage = {
            home = "/home/carlesoctav/personal/proof-by-ac/leetgpu",
            cache = vim.fn.stdpath("cache") .. "/leetgpu",
        },
    },
}
