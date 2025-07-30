return {
	"nvim-telescope/telescope.nvim",
	keys = {
		{
			"<leader>fc",
			function()
				require("telescope.builtin").resume()
			end,
			desc = "resume last picker",
		},
		{
			"<leader>ff",
			function()
				require("telescope.builtin").find_files()
			end,
			desc = "fuzzy files",
		},
		{
			"<leader>fg",
			function()
				require("telescope.builtin").live_grep()
			end,
			desc = "fuzzy live grep",
		},
		{
			"<leader>ft",
			function()
				require("telescope.builtin").treesitter()
			end,
			desc = "treesitter picker",
		},
		{
			"<leader>fr",
			function()
				require("telescope.builtin").registers()
			end,
			desc = "registers picker",
		},
		{
			"<leader>fw",
			function()
				local builtin = require("telescope.builtin")
				local word = vim.fn.expand("<cword>")
				builtin.grep_string({ search = word })
			end,
			desc = "search word",
		},
		{
			"<leader>fW",
			function()
				local builtin = require("telescope.builtin")
				local word = vim.fn.expand("<cWORD>")
				builtin.grep_string({ search = word })
			end,
			desc = "search WORD",
		},
		{
			"<leader>fs",
			function()
				local builtin = require("telescope.builtin")
				builtin.grep_string({ search = vim.fn.input("Grep > ") })
			end,
			desc = "search word from input",
		},
	},
	cmd = { "Telescope" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {
		defaults = {
			layout_config = {
				prompt_position = "top",
				preview_width = 0.6,
			},
			path_display = { truncate = 4 },
			sorting_strategy = "ascending",
			dynamic_preview_title = true,
		},
		extensions = {
			workspaces = {},
		},
	},
}
