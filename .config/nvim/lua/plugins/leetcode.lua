return {
    "kawre/leetcode.nvim",
    dependencies = {
        -- include a picker of your choice, see picker section for more details
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        -- configuration goes here
        lang = "python3",
        storage = {
            home = "/home/carlesoctav/personal/proof-by-ac/leetcode/python",
            cache = vim.fn.stdpath("cache") .. "/leetcode",
        },
        injector = {
            ["cpp"] = {
                before = { "#include <bits/stdc++.h>", "using namespace std;" },
                after = "int main() {}",
            },
            ["python3"] = {
                before = "from typing import *"
            },
            ["java"] = {
                before = "import java.util.*;",
            },
            ["golang"] = {
                before = "package main",
            }
        }
    },
}
