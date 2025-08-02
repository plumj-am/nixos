vim.bo.tabstop = 8
vim.bo.shiftwidth = 8
vim.bo.softtabstop = 8

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
