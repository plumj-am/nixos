local function file_info()
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

local function lualine_custom_no_icons()
	local fe = vim.o.fileencoding
	local ff = vim.o.fileformat
	local ft = vim.o.filetype

	if fe == "" or ff == "" or ft == "" then
		return ""
	elseif fe ~= "utf-8" and ff ~= "unix" then
		return fe .. " :: " .. ff .. " :: " .. ft
	elseif fe ~= "utf-8" and ff == "unix" then
		return fe .. " :: " .. ft
	elseif fe == "utf-8" and ff ~= "unix" then
		return ff .. " :: " .. ft
	else
		return ft
	end
end

local function pomo_timer()
	local ok, pomo = pcall(require, "pomo")
	if not ok then return "" end

	local timer = pomo.get_first_to_finish()
	if timer == nil then return "" end

	return "󰄉 " .. tostring(timer)
end

local filename = { "filename", show_filename_only = false, path = 1 }
local diagnostics = {
	"diagnostics",
	symbols = {
		error = "",
		warn = "",
		info = "",
		hint = "",
	},
}

return {
	"nvim-lualine/lualine.nvim",
	lazy = false,
	priority = 900,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "auto",
			disabled_filetypes = { "no-neck-pain" },
			section_separators = "",
			component_separators = "",
			icons_enabled = true,
		},
		-- extensions = { "lazy", "mason", "toggleterm", "quickfix", "fugitive", "lazy", "trouble" },
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", diagnostics },
			lualine_c = { filename, "diff" },
			lualine_x = { pomo_timer },
			lualine_y = { file_info, "filetype" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", diagnostics },
			lualine_c = { filename, "diff" },
			lualine_x = { pomo_timer },
			lualine_y = { file_info, "filetype" },
			lualine_z = { "location" },
		},
	},
}
