return {
	"uga-rosa/ccc.nvim",
	cmd = "CccHighlighterToggle",
	keys = {
		{
			"<leader>ccc",
			"<cmd>CccHighlighterToggle<CR>",
			desc = "Toggle ccc",
			silent = true,
		},
	},
	opts = {
		highlighter = {
			auto_enable = false,
			lsp = true,
		},
	},
}
