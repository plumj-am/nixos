-- Trailing whitespace highlight
SET_HL(0, "ws", { bg = "red" })
vim.fn.matchadd("ws", [[\s\+$]])
AUTOCMD("InsertEnter", {
	callback = function()
		vim.fn.clearmatches()
	end,
})
AUTOCMD("InsertLeave", {
	callback = function()
		vim.fn.matchadd("ws", [[\s\+$]])
	end,
})

-- Yank highlight
AUTOCMD("TextYankPost", {
	callback = function()
		vim.highlight.on_yank({ higroup = "Visual", timeout = 500 })
	end,
})

-- Auto-resize windows
AUTOCMD("VimResized", {
	pattern = "*",
	callback = function()
		CMD("wincmd =")
	end,
})

-- Remove trailing whitespace on save
AUTOCMD("BufWritePre", {
	pattern = "*",
	command = [[%s/\s\+$//e]],
})
