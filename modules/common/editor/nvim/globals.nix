{
	programs.nvf.settings.vim.luaConfigRC.globals = ''
		-- Global functions
		function ColorMyPencils(color, theme, transparent)
			vim.o.background = theme or "light"
			vim.cmd.colorscheme(color or "default")
			require("fidget").notify("background: " .. vim.o.background .. "\n theme: " .. theme .. "\n colorscheme: " .. color)

			-- general tweaks
			if transparent then
				vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
				vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
			end

			if theme == "dark" then
				vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#BFBFBF", bold = false })
				vim.api.nvim_set_hl(0, "LineNr", { fg = "white", bold = true })
				vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#BFBFBF", bold = false })
			end

			vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#808080" })

			-- fixes for colorschemes
			if color == "rusticated" then
				FixRusticated()
			end
			if color == "rasmus" then
				FixRasmus()
			end
			if color == "gruvbox-material" and theme == "light" then
				vim.api.nvim_set_hl(0, "LineNrAbove", { fg = "#7C6F64", bold = true })
				vim.api.nvim_set_hl(0, "LineNrBelow", { fg = "#7C6F64", bold = true })
				vim.api.nvim_set_hl(0, "LineNr", { fg = "#4f3829", bold = true })
			end
		end

		function DisableItalic()
			local hl_groups = vim.api.nvim_get_hl(0, {})

			for key, hl_group in pairs(hl_groups) do
				if hl_group.italic then
					vim.api.nvim_set_hl(0, key, vim.tbl_extend("force", hl_group, { italic = false }))
				end
			end
		end

		function DisableBold()
			local hl_groups = vim.api.nvim_get_hl(0, {})

			for key, hl_group in pairs(hl_groups) do
				if hl_group.bold then
					vim.api.nvim_set_hl(0, key, vim.tbl_extend("force", hl_group, { bold = false }))
				end
			end
		end

		function DisableUndercurl()
			local highlights = {
				DiagnosticUnderlineError = { undercurl = false, underline = true },
				DiagnosticUnderlineWarn = { undercurl = false, underline = true },
				DiagnosticUnderlineInfo = { undercurl = false, underline = true },
				DiagnosticUnderlineHint = { undercurl = false, underline = true },
			}

			for group, opts in pairs(highlights) do
				vim.api.nvim_set_hl(0, group, opts)
			end
		end

		function FixRasmus()
			local highlights = {
				SpellBad = { undercurl = false, underline = true },
				SpellCap = { undercurl = false, underline = true },
				SpellLocal = { undercurl = false, underline = true },
				SpellRare = { undercurl = false, underline = true },
				DiffAdd = { reverse = false },
				DiffChange = { reverse = false },
				DiffDelete = { reverse = false },
			}

			for group, opts in pairs(highlights) do
				vim.api.nvim_set_hl(0, group, opts)
			end
		end

		function FixRusticated()
			vim.api.nvim_set_hl(0, "DiffAdd", {
				fg = "#1e1e1e",
				bg = "#98c379",
			})

			vim.api.nvim_set_hl(0, "DiffAdded", {
				fg = "#1e1e1e",
				bg = "#98c379",
			})

			vim.api.nvim_set_hl(0, "DiffTextAdd", {
				fg = "#1e1e1e",
				bg = "#98c379",
			})

			vim.api.nvim_set_hl(0, "DiffText", {
				fg = "#1e1e1e",
				bg = "#98c379",
			})
		end

		function ToggleDirbuf()
			if vim.bo.filetype == "dirbuf" then
				vim.cmd("DirbufQuit")
			else
				vim.cmd("Dirbuf")
			end
		end

		function LualineFileInfo()
			local fe = vim.o.fileencoding
			local ff = vim.o.fileformat

			if fe == "" or ff == "" then
				return ""
			elseif fe ~= "utf-8" and ff ~= "unix" then
				return fe .. " :: " .. ff .. " :: "
			elseif fe ~= "utf-8" and ff == "unix" then
				return fe .. " :: "
			elseif fe == "utf-8" and ff ~= "unix" then
				return ff .. " :: "
			else
				return ""
			end
		end

    function OpenTodo() vim.cmd("edit ~/notes/todo.md") end

    vim.api.nvim_create_user_command("TD", OpenTodo, { desc = "Open ~/notes/todo.md" })
	'';
}
