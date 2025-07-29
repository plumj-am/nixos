-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local out = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})

	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end

vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
	spec = {
		{ import = "themes" },
		{ import = "plugins" },
		{ import = "lsp" },
	},
	change_detection = { notify = false },
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "auto" } },
	-- automatically check for plugin updates
	checker = { enabled = true, notify = true, concurrency = 24 },
	ui = { border = "single", backdrop = 95 },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
				"matchit",
				"rplugin",
			},
		},
	},
})

AUTOCMD("VimEnter", {
	callback = function()
		require("lazy").update({ show = false })
	end,
})
