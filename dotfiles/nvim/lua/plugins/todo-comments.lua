return {
	"folke/todo-comments.nvim",
	event = "BufRead",
	-- cmd = "TodoTelescope",
	keys = {
		{
			"<leader>td",
			"<cmd>TodoTelescope<CR>",
			desc = "todo list in telescope",
		},
	},
	opts = {
		signs = false,
		highlight = {
			before = "",
			keyword = "wide",
			after = "",
		},
	},
}
