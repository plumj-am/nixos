local light_theme = "zenwritten"
local dark_theme = "zenbones"
local current_theme = light_theme

local bg = current_theme == dark_theme and "dark" or "light"

ColorMyPencils(current_theme, bg, true)
-- DisableBold()
DisableItalic()
DisableUndercurl()
