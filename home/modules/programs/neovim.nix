{
  imports = [
    ./nvf/themes.nix
    ./nvf/plugins.nix
    ./nvf/options.nix
    ./nvf/lsp.nix
    ./nvf/highlights.nix
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.nvf = {
    enable = true;
    settings = {
      vim.viAlias = true;
      vim.vimAlias = true;
    };
  };
}
