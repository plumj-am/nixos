return {
	"vuki656/package-info.nvim",
	event = "BufRead package.json",
	opts = {
		autostart = true,
		hide_unstable_versions = true,
		notifications = false,
		icons = {
			enable = true,
			style = {
				up_to_date = "   ",
				outdated = "   ",
				invalid = "   ",
			},
		},
	},
	config = function()
		-- only working way to set the colors https://github.com/vuki656/package-info.nvim/issues/155#issuecomment-2270572104
		SET_HL(0, "PackageInfoUpToDateVersion", { fg = "#3c4048" })
		SET_HL(0, "PackageInfoOutdatedVersion", { fg = "#d19a66" })
		SET_HL(0, "PackageInfoInvalidVersion", { fg = "#ee4b2b" })

		CMD("lua require('package-info').show({ force = true })")
	end,
}
