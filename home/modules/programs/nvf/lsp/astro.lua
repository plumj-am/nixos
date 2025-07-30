return {
	cmd = { "astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_markers = { "package.json", "bun.lock", "tsconfig.json" },
	settings = {},
	init_options = {
		typescript = {
			tsdk = "node_modules/typescript/lib",
		},
	},
}
