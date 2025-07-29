return {
	"ej-shafran/compile-mode.nvim",
	cmd = "Compile",
	init = function()
		vim.g.compile_mode = {
			baleia_setup = true,
			default_command = "",
			recompile_no_fail = true,
		}
	end,
	keys = {
		{
			"<leader>co",
			":vert Compile<cr>",
			desc = "run a compile cmd",
		},
		{
			"<leader>cr",
			":vert Recompile<cr>",
			desc = "rerun last compile cmd",
		},
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "m00qek/baleia.nvim", tag = "v1.3.0" },
	},
}
