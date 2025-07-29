return {
	"vimwiki/vimwiki",
	keys = { "<leader>ww", "<leader>wi" },
	init = function()
		vim.g.vimwiki_option_diary_path = "./diary/"
		vim.g.vimwiki_global_ext = 0
		vim.g.vimwiki_option_nested_syntaxes = { svelte = "svelte", typescript = "ts" }
		vim.g.vimwiki_list = {
			{
				path = "~/vimwiki/james/",
				name = "james",
				syntax = "markdown",
				ext = "md",
			},
			{
				path = "~/vimwiki/healgorithms/",
				name = "healgorithms",
				syntax = "markdown",
				ext = "md",
				auto_toc = 1,
			},
		}
	end,
}
