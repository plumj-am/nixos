local lsp = vim.lsp

lsp.set_log_level("off")

local c = vim.tbl_deep_extend(
	"force",
	{},
	vim.lsp.protocol.make_client_capabilities(),
	require("blink.cmp").get_lsp_capabilities()
)

lsp.config["*"] = {
	capabilities = c,
	root_markers = { ".git" },
}

lsp.enable({
	"astro",
	-- "bacon-ls",
	"gopls",
	"json_ls",
	"lua_ls",
	"nushell",
	"rust_analyzer",
	"svelteserver",
	"tailwindcss",
	"ts_ls",
	"yamlls",
})

local orig_util_open_floating_preview = lsp.util.open_floating_preview
function lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or "single"
	opts.max_width = opts.max_width or 60
	opts.focusable = opts.focusable or false
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- trying tiny-inline-diagnostic.nvim for a while
-- AUTOCMD("CursorHold", {
-- 	callback = function()
-- 		vim.diagnostic.open_float()
-- 	end,
-- })

local function reload_lsp()
	CMD("lua vim.lsp.stop_client(vim.lsp.get_clients())")

	local function check_and_reload()
		if not lsp.buf_is_attached(0) then
			CMD.edit()
		else
			vim.defer_fn(check_and_reload, 50)
		end
	end
	vim.defer_fn(check_and_reload, 50)
end

CREATE_CMD("LspReload", reload_lsp, { desc = "Reload attached LSP" })

AUTOCMD("LspAttach", {
	callback = function(args)
		vim.diagnostic.config({
			update_in_insert = false,
			virtual_text = false,
			float = {
				focusable = false,
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})
		local client = lsp.get_client_by_id(args.data.client_id)

		MAP("n", "<leader>ih", function()
			if vim.lsp.inlay_hint.is_enabled() then
				vim.lsp.inlay_hint.enable(false)
			else
				vim.lsp.inlay_hint.enable(true)
			end
		end)

		if client:supports_method("textDocument/foldingRange") then
			vim.wo.foldmethod = "expr"
			vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
		else
			vim.wo.foldmethod = "indent"
		end
		MAP("n", "gd", function()
			lsp.buf.definition()
		end, { desc = "Go to definition" })
		MAP("n", "gr", function()
			lsp.buf.references()
		end, { desc = "Show references" })
		MAP("n", "grn", function()
			lsp.buf.rename()
		end, { desc = "vim.lsp rename" })
		MAP("n", "gi", function()
			lsp.buf.implementation()
		end, { desc = "vim.lsp implementation" })
		MAP({ "n", "v" }, "ga", function()
			lsp.buf.code_action()
		end, { desc = "vim.lsp code action" })
		MAP("n", "K", function()
			lsp.buf.hover()
		end, { desc = "Hover" })
	end,
})

return {}
