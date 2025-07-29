return {
	"eliseshaffer/darklight.nvim",
	opts = {
		mode = "custom",
		light_mode_callback = function()
			ColorMyPencils("rusticated", "light", true)
			DisableBold()
			DisableItalic()
		end,
		dark_mode_callback = function()
			ColorMyPencils("rasmus", "dark", true)
			DisableBold()
			DisableItalic()
		end,
	},
}
