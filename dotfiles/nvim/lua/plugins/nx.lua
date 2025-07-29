return {
	"Equilibris/nx.nvim",
	keys = {
		{ "<leader>nx", ":Telescope nx actions<CR>", desc = "view nx actions" },
	},
	opts = {
		nx_cmd_root = "bunx nx",
	},
}
