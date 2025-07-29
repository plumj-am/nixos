return {
	"saghen/blink.cmp",
	event = "BufRead",
	enabled = true,
	version = "1.4", -- NOTE: 1.4 until fixed: https://github.com/LazyVim/LazyVim/pull/6183
	build = "cargo build --release",
	opts = {
		keymap = { preset = "enter" },
		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 250 },
			menu = {
				draw = {
					columns = {
						{ "kind" },
						{ "label", gap = 1 },
					},
				},
			},
		},
		cmdline = { enabled = false },
		-- 	completion = {
		-- 		menu = {
		-- 			auto_show = false,
		-- 			draw = {
		-- 				columns = {
		-- 					{ "label", "label_description", gap = 1 },
		-- 				},
		-- 			},
		-- 		},
		-- 	},
		-- },
		signature = { enabled = true },
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			providers = {
				buffer = {
					opts = {
						get_bufnrs = function()
							return vim.tbl_filter(function(bufnr)
								return vim.bo[bufnr].buftype == ""
							end, vim.api.nvim_list_bufs())
						end,
					},
				},
			},
		},
	},
}
