return {
	"nvzone/typr",
	dependencies = "nvzone/volt",
	opts = {
		config = {
			on_attach = function()
				vim.bo.wrap = false
				vim.bo.completion = false
			end,
		},
	},
	cmd = { "Typr", "TyprStats" },
}
