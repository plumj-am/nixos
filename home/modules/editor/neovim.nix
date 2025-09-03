{ lib, ... }:
let
	inherit (lib) enabled;
in
{
  imports = [ ./nvim ];

  programs.vim = enabled;

  programs.nvf = enabled {
    settings = {
      vim.viAlias = true;
      vim.vimAlias = true;
    };
  };
}
