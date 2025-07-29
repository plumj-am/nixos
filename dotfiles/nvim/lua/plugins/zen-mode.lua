return {
	"folke/zen-mode.nvim",
	cmd = "ZenMode",
	opts = {
		on_open = function()
			vim.wo.colorcolumn = "0"
		end,
		window = {
			width = 80,
			height = 1,
		},
		plugins = {
			options = {
				enabled = true,
				showcmd = true,
				ruler = false,
				laststatus = 0,
			},
			twilight = { enabled = true },
			gitsigns = { enabled = false },
		},
	},
}
