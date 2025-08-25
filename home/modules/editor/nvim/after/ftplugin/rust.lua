vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4

local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "ga", function()
	vim.cmd.RustLsp("codeAction") -- supports rust-analyzer's grouping
end, { silent = true, buffer = bufnr })
vim.keymap.set(
	"n",
	"K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
	function()
		vim.cmd.RustLsp({ "hover", "actions" })
	end,
	{ silent = true, buffer = bufnr }
)
