return {
	"nvim-treesitter/nvim-treesitter-context",
	event = "BufRead",
	opts = {
		max_lines = 3,
		separator = "-",
	},
	config = function()
		SET_HL(0, "TreesitterContextLineNumberBottom", {
			fg = "#FFFFFF",
		})
		SET_HL(0, "TreesitterContextSeparator", {
			fg = "#363636",
		})
	end,
}
