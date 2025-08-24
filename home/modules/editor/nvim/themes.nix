{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    theme = {
      enable = false;
      name = "gruvbox";
      style = "dark";
    };

    luaConfigRC.theme = # lua
      ''
        -- custom theme configuration
      '';

    extraPlugins = {
      "vimplugin-rusticated" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "rusticated";
          src = pkgs.fetchFromGitHub {
            owner = "haystackandroid";
            repo = "rusticated";
            rev = "8052162f2c602725b4c0faf1d003404d5b9140c2";
            sha256 = "sha256-PF5rUyEMi05HsimfrfqpXNY6RAEBHctpBoJh733jogE=";
          };
        };
      };

      "vimplugin-rasmus.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "rasmus.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "kvrohit";
            repo = "rasmus.nvim";
            rev = "49f7ee7bf3eb00db52c77f84b15bc69f318bafc1";
            sha256 = "sha256-MWc6zzMGZ6OceZGbx2qmuHe9FvIUXK1rtb+yIsfRokY=";
          };
        };
      };

      "vimplugin-zenbones.nvim" = {
        package = pkgs.vimPlugins.zenbones-nvim;
      };

      # for zenbones
      "vimplugin-lush.nvim" = {
        package = pkgs.vimPlugins.lush-nvim;
      };

      "gruvbox-material.nvim" = {
        package = pkgs.vimPlugins.gruvbox-material-nvim;
        setup = "require('gruvbox-material').setup({contrast='hard'})";

      };
    };
  };
}
