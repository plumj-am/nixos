local light_theme = "gruvbox-material"
local dark_theme = "gruvbox-material"
local current_theme = dark_theme

local bg = current_theme == dark_theme and "dark" or "light"

ColorMyPencils(current_theme, bg, false)
-- DisableBold()
DisableItalic()
DisableUndercurl()
