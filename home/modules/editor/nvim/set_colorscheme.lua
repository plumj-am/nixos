-- theme configuration from nix globals
local current_theme = vim.g.theme_name
local bg = vim.g.theme_variant

ColorMyPencils(current_theme, bg, false)
-- DisableBold()
DisableItalic()
DisableUndercurl()
