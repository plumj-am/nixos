function ToggleDirbuf()
	if vim.bo.filetype == "dirbuf" then
		vim.cmd("DirbufQuit")
	else
		vim.cmd("Dirbuf")
	end
end

return {}
