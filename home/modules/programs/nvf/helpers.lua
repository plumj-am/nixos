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

function LualinePomoTimer()
	local ok, pomo = pcall(require, "pomo")
	if not ok then return "" end

	local timer = pomo.get_first_to_finish()
	if timer == nil then return "" end

	return "󰄉 " .. tostring(timer)
end

LualineDiagnostics = {
	"diagnostics",
	symbols = {
		error = "",
		warn = "",
		info = "",
		hint = "",
	},
}

LualineFilename = {
	"filename",
	show_filename_only = false,
	path = 1
}

return {}
