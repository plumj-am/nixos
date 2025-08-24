local light_theme = "gruvbox-material"
local dark_theme = "gruvbox-material"
local use_light_theme = false

local current_theme = dark_theme and light_theme or dark_theme
local bg = use_light_theme and "light" or "dark"

ColorMyPencils(current_theme, bg, false)
-- DisableBold()
DisableItalic()
DisableUndercurl()
