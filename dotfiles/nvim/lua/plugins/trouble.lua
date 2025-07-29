return {
	"folke/trouble.nvim",
	event = "LspAttach",
	keys = {
		{
			"<leader>tr",
			"<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>",
			desc = "Trouble diagonostics current file",
		},
		{
			"<leader>te",
			"<cmd>Trouble diagnostics toggle focus=true<cr>",
			desc = "Trouble diagonostics all files",
		},
		{
			"<leader>tq",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Trouble quickfix list",
		},
	},
	opts = {
		auto_close = true,
		modes = {
			diagnostics = { -- Configure symbols mode
				win = {
					size = 0.3, -- 30% of the window})
					-- },
					--preview = {
					--    type = "float",
					--    relative = "win",
					--    title = "Preview",
					--    border = "single",
					--size = { width = 0.25, height = 0.4 },
					--    zindex = 200,
					--},
				},
			},
		},
	},
}
