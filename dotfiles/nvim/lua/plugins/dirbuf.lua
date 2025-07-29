return {
	"elihunter173/dirbuf.nvim",
	cmd = "Dirbuf",
	keys = {
		{
			"<C-s>",
			function()
				if vim.bo.filetype == "dirbuf" then
					CMD("DirbufQuit")
				else
					CMD("Dirbuf")
				end
			end,
			desc = "Open dirbuf",
		},
		{
			"-",
			":Dirbuf<CR>",
		},
	},
	opts = {
		sort_order = "directories_first",
		write_cmd = "DirbufSync -confirm",
		show_hidden = true,
	},
}
