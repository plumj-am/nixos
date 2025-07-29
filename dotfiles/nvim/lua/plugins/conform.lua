return {
	"stevearc/conform.nvim",
	event = "BufRead",
	opts = {
		formatters = {
			-- Use system binaries without .exe extension
			prettier = {
				command = "prettier",
			},
			prettierd = {
				command = "prettierd",
			},
		},
		formatters_by_ft = {
			astro = { "prettierd", "prettier", stop_after_first = true },
			go = { "gofumpt", "goimports", stop_after_first = true },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			svelte = { "prettierd", "prettier", stop_after_first = true },
			vue = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			md = { "dprint" },
			toml = { "dprint" },
			lua = { "stylua" },
			sql = { "sql_formatter" },
			python = { "ruff_format" },
			rust = { "rustfmt" },
			-- nu = { "nufmt" },
			nix = { "nixfmt" },
		},
		format_after_save = {
			async = true,
			-- lsp_format = "fallback",
		},
	},
}
