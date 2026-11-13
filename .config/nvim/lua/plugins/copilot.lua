return {
	"github/copilot.vim",
	event = "InsertEnter",
	cmd = "Copilot",
	init = function()
		vim.g.copilot_enabled = false
	end,
}

