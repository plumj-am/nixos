return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "BufReadPost",
	opts = {
		preset = "minimal",
		transparent_bg = true,
		transparent_cursorline = false,
		signs = {
			arrow = "",
			up_arrow = "",
		},
		options = {
			show_source = { enabled = true },
			multilines = { enabled = true, always_show = true },
			throttle = 100,
		},
	},
}
