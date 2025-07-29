return {
	"echasnovski/mini.bufremove",
	event = "BufRead",
	opts = {},
	keys = {
		{
			"<leader>qb",
			function()
				CMD("lua MiniBufremove.delete()")
			end,
			desc = "close buffer",
		},
	},
}
