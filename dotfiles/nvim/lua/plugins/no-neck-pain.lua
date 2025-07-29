return {
	"shortcuts/no-neck-pain.nvim",
	lazy = false,
	priority = 1001,
	opts = {
		width = 110,
		autocmds = {
			enableOnVimEnter = true,
			skipEnteringNoNeckPainBuffer = true,
		},
		buffers = {
			wo = {
				fillchars = "eob: ",
			},
		},
	},
}
