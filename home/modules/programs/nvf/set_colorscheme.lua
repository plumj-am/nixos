local light_theme = "rusticated"
local dark_theme = "rasmus"
local current_theme = dark_theme

local bg = current_theme == dark_theme and "dark" or "light"

ColorMyPencils(current_theme, bg, true)
DisableBold()
DisableItalic()
DisableUndercurl()
