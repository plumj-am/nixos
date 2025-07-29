return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				checkThirdParty = true,
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
}
