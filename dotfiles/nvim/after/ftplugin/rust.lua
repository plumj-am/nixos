vim.bo.tabstop = 8
vim.bo.shiftwidth = 8
vim.bo.softtabstop = 8

-- was for rustaceanvim but now using ferris.nvim

-- local bufnr = vim.api.nvim_get_current_buf()
-- -- MAP("n", "<leader>a", function()
-- -- 	CMD.RustLsp("codeAction") -- supports rust-analyzer's grouping
-- -- or lsp.buf.codeAction() if you don't want grouping.
-- -- end, { silent = true, buffer = bufnr })
-- MAP(
-- 	"n",
-- 	"K", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
-- 	function() CMD.RustLsp({ "hover", "actions" }) end,
-- 	{ silent = true, buffer = bufnr }
-- )
