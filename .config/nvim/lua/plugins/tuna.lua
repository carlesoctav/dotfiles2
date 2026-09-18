return {
    "FrancescoDerme/tuna.nvim",
    opts = {
        -- language new solutions are created in (used for $(FEXT))
        downloaded_files_extension = "py",
        -- scratch file from :Tuna temp uses Python too
        temp = { extension = "py" },
        -- single problem: ~/personal/proof-by-ac/cp/<judge>/<problem>/main.<ext>
        downloaded_problems_path = "/home/carlesoctav/personal/proof-by-ac/cp/$(JUDGE)/$(PROBLEM)/main.$(FEXT)",
        -- contest: ~/personal/proof-by-ac/cp/<judge>/<contest>/<problem>/main.<ext>
        downloaded_contests_directory = "/home/carlesoctav/personal/proof-by-ac/cp/$(JUDGE)/$(CONTEST)",
        downloaded_contests_problems_path = "$(PROBLEM)/main.$(FEXT)",
        compile_command = {
            cpp = { exec = "g++", args = { "-std=c++20", "-O2", "-Wall", "$(FNAME)", "-o", "$(FNOEXT)" } },
        },
        keymaps = { preset = "<leader>t" },
    },
}
