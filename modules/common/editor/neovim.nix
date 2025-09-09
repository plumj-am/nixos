{ pkgs, lib, config, ... }:
let
  inherit (lib) enabled;
in
{
  imports = [ ./nvim ];

  programs.vim = enabled;

  programs.nvf = enabled {

    settings.vim = {
      enableLuaLoader = true;

      additionalRuntimePaths = [ ./nvim/after ];
      extraLuaFiles          = [
        (builtins.path { path = ./nvim/set_colorscheme.lua; })
      ];

      clipboard = enabled {
        registers = "unnamedplus";
        providers.wl-copy.enable = lib.mkIf pkgs.stdenv.isLinux true;
      };

      globals = {
        mapleader = " ";

        editorconfig = true;

        loaded_netrw       = 1;
        loaded_netrwPlugin = 1;

        # theme configuration for lua
        theme_name    = config.theme.nvim;
        theme_variant = config.theme.variant;
        is_dark       = config.theme.is_dark;
      };

      options = {
        # line numbers
        number         = true;
        relativenumber = true;

        # search
        ignorecase = true;
        smartcase  = true;

        # indentation
        tabstop     = 4;
        shiftwidth  = 4;
        softtabstop = 4;
        smartindent = true;

        # split handling
        splitbelow = true;
        splitright = true;

        # ui
        wrap          = false;
        pumheight     = 8;
        termguicolors = true;
        cursorline    = true;
        showmode      = false;
        showtabline   = 0;
        guicursor     = "";
        fillchars     = "eob:~,fold: ,foldopen:,foldsep: ,foldclose:,vert:┃,lastline:┃";
        winborder     = "single";

        # backups etc.
        undofile    = true;
        swapfile    = false;
        backup      = false;
        writebackup = false;

        # scrolling
        scrolloff     = 8;
        sidescrolloff = 10;
        smoothscroll  = true;

        # misc
        updatetime  = 50;
        mouse       = "";
        completeopt = "menuone,noselect";
        foldenable  = false;
      };
    };
  };
}
