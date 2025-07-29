return {
	"jamesukiyo/quicksnip.vim",
	cmd = { "SnipCurrent", "SnipPick" },
	keys = { { "<leader>sp", ":SnipPick<CR>" }, { "<leader>sc", ":SnipCurrent<CR>" } },
	init = function()
		vim.g.miniSnip_dirs = { "~/.vim/snippets" }
		vim.g.miniSnip_trigger = "<C-c>"
		vim.g.miniSnip_complkey = ""
		vim.g.miniSnip_extends = {
			html = { "svelte" },
			svelte = { "typescript", "html" },
			javascript = { "typescript" },
			typescript = { "javascript" },
		}
	end,
}
