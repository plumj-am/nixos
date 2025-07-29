return {
	"natecraddock/workspaces.nvim",
	cmd = "Telescope workspaces",
	keys = {
		{
			"<leader>fp",
			":Telescope workspaces<CR>",
			desc = "open project list",
		},
	},
	opts = {
		auto_open = true,
	},
	config = function()
		require("telescope").load_extension("workspaces")
	end,
}
