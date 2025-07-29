return {
	cmd = { "bunx", "--bun", "typescript-language-server", "--stdio" },
	root_markers = { "package.json", "bun.lock", "package-lock.json" },
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				location = vim.fn.exepath("vue-language-server"),
				languages = { "vue" },
			},
		},
	},
	filetypes = {
		"typescript",
		"javascript",
		"javascriptreact",
		"typescriptreact",
		"vue",
	},
}
