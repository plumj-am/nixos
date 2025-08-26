local lsp = vim.lsp

lsp.set_log_level("off")

local orig_util_open_floating_preview = lsp.util.open_floating_preview
function lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.max_width = opts.max_width or 60
	opts.focusable = opts.focusable or false
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- trying tiny-inline-diagnostic.nvim for a while
-- vim.api.nvim_create_autocmd("CursorHold", {
-- 	callback = function()
-- 		vim.diagnostic.open_float()
-- 	end,
-- })

local function reload_lsp()
	vim.cmd("lua vim.lsp.stop_client(vim.lsp.get_clients())")

	local function check_and_reload()
		if not lsp.buf_is_attached(0) then
			vim.cmd.edit()
		else
			vim.defer_fn(check_and_reload, 50)
		end
	end
	vim.defer_fn(check_and_reload, 50)
end

vim.api.nvim_create_user_command("LspReload", reload_lsp, { desc = "Reload attached LSP" })

return {}
