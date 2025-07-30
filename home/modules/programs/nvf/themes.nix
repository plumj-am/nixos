{
  programs.nvf.settings.vim = {
    theme = {
      enable = true;
      name = "gruvbox";
      style = "dark";
    };

    luaConfigRC.theme = # lua
      ''
        -- custom theme configuration
      '';
  };
}
