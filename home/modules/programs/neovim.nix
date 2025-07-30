{
  imports = [
    ./nvf/themes.nix
    ./nvf/plugins.nix
    ./nvf/options.nix
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.nvf = {
    enable = true; # disabled initially for gradual migration
    settings = {
      vim.viAlias = true;
      vim.vimAlias = true;
    };
  };
}
