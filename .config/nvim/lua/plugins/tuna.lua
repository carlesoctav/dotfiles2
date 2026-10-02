return {
    "FrancescoDerme/tuna.nvim",
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
}
