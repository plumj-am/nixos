{
  imports = [
    ./nvim/themes.nix
    ./nvim/plugins-nvf.nix
    ./nvim/plugins-custom.nix
    ./nvim/options.nix
    ./nvim/keymaps.nix
    ./nvim/autocmds.nix
    ./nvim/lsp.nix
    ./nvim/highlights.nix
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
