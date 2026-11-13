local leet_deps = {
	"nvim-lua/plenary.nvim",
	"MunifTanjim/nui.nvim",
}

return {
	{
		dir = "/home/carlesoctav/personal/leetcode.nvim",
		name = "leetcode.nvim",
		cmd = "Leet",
		dependencies = leet_deps,
		opts = {
			lang = "python3",
			picker = { provider = "mini-picker" },
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
					before = "from typing import *",
				},
				["java"] = {
					before = "import java.util.*;",
				},
				["golang"] = {
					before = "package main",
				},
			},
		},
	},
	{
		dir = "/home/carlesoctav/personal/leetgpu",
		name = "leetgpu.nvim",
		cmd = "LeetGpu",
		dependencies = leet_deps,
		opts = {
			lang = "jax",
			accelerator = "TPU v5e",
			storage = {
				home = "/home/carlesoctav/personal/proof-by-ac/leetgpu",
				cache = vim.fn.stdpath("cache") .. "/leetgpu",
			},
		},
	},
	{
		"FrancescoDerme/tuna.nvim",
		cmd = "Tuna",
		keys = { { "<leader>t", desc = "Tuna" } },
		opts = {
			downloaded_files_extension = "py",
			temp = { extension = "py" },
			downloaded_problems_path = "/home/carlesoctav/personal/proof-by-ac/cp/$(JUDGE)/$(PROBLEM)/main.$(FEXT)",
			downloaded_contests_directory = "/home/carlesoctav/personal/proof-by-ac/cp/$(JUDGE)/$(CONTEST)",
			downloaded_contests_problems_path = "$(PROBLEM)/main.$(FEXT)",
			compile_command = {
				cpp = { exec = "g++", args = { "-std=c++20", "-O2", "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
			},
			keymaps = { preset = "<leader>t" },
		},
	},
}
