{ lib, ... }:
let
  mkLuaInline = lib.generators.mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    enableLuaLoader = true;
    extraLuaFiles = [
      (builtins.path {
        path = ./globals.lua;
      })
      (builtins.path {
        path = ./helpers.lua;
      })
      (builtins.path {
        path = ./lsp.lua;
      })
      (builtins.path {
        path = ./lsp/bacon_ls.lua;
      })
      (builtins.path {
        path = ./lsp/json_ls.lua;
      })
    ];

    clipboard = {
      enable = true;
      registers = "unnamedplus";
    };

    globals = {
      mapleader = " "; # space as leader key
      editorconfig = true;
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    options = {
      number = true;
      relativenumber = true;
      ignorecase = true;
      smartcase = true;
      incsearch = true;
      hlsearch = true;
      tabstop = 8;
      shiftwidth = 8;
      softtabstop = 8;
      expandtab = false;
      autoindent = true;
      smartindent = true;
      splitbelow = true;
      splitright = true;
      wrap = false;
      termguicolors = true;
      cursorline = true;
      colorcolumn = "80";
      showmode = false;
      showtabline = 0;
      signcolumn = "no";
      undofile = true;
      swapfile = false;
      backup = false;
      writebackup = false;
      scrolloff = 8;
      sidescrolloff = 10;
      pumheight = 8;
      cmdheight = 1;
      updatetime = 50;
      mouse = "";
      guicursor = "";
      completeopt = "menuone,noselect";
      fileformat = "unix";
      fileformats = "unix,dos";
      conceallevel = 0;
      foldcolumn = "0";
      foldenable = false;
      foldlevel = 99;
      foldlevelstart = 99;
      foldmethod = "indent";
      autochdir = false;
      fillchars = "eob:~,fold: ,foldopen:,foldsep: ,foldclose:,vert:▏,lastline:▏";
      smoothscroll = true;
    };

    keymaps = [
      # clipboard mappings (thanks primeagen)
      {
        key = "<leader>p";
        mode = "x";
        action = ''"_dP'';
        desc = "paste over text but keep clipboard";
      }
      {
        key = "<leader>y";
        mode = [
          "n"
          "v"
        ];
        action = ''"+y'';
        desc = "yank selection to system clipboard";
      }
      {
        key = "<leader>Y";
        mode = "n";
        action = ''"+Y'';
        desc = "yank line to system clipboard";
      }
      {
        key = "<leader>d";
        mode = [
          "n"
          "v"
        ];
        action = ''"_d'';
        desc = "delete without yank";
      }
      {
        key = "J";
        mode = "n";
        action = "mzJ`z";
        desc = "better line joins";
      }
      {
        key = "J";
        mode = "v";
        action = ":m '>+1<CR>gv=gv";
        desc = "move line down";
      }
      {
        key = "K";
        mode = "v";
        action = ":m '<-2<CR>gv=gv";
        desc = "move line up";
      }
      {
        key = "<leader>sr";
        mode = "n";
        action = '':%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>'';
        desc = "instant search and replace current word";
      }
      {
        key = "<C-d>";
        mode = "n";
        action = "<C-d>zz";
        desc = "1/2 page down + center cursor";
      }
      {
        key = "<C-u>";
        mode = "n";
        action = "<C-u>zz";
        desc = "1/2 page up + center cursor";
      }
      {
        key = "n";
        mode = "n";
        action = "nzz";
        desc = "center cursor on next search result";
      }
      {
        key = "N";
        mode = "n";
        action = "Nzz";
        desc = "center cursor on previous search result";
      }
      {
        key = "<C-d>";
        mode = "v";
        action = "<C-d>zz";
        desc = "1/2 page down + center cursor";
      }
      {
        key = "<C-u>";
        mode = "v";
        action = "<C-u>zz";
        desc = "1/2 page up + center cursor";
      }
      {
        key = "n";
        mode = "v";
        action = "nzz";
        desc = "center cursor on next search result";
      }
      {
        key = "N";
        mode = "v";
        action = "Nzz";
        desc = "center cursor on previous search result";
      }
      {
        key = "H";
        mode = "n";
        action = "^";
        desc = "move to first non-blank character of line";
      }
      {
        key = "L";
        mode = "n";
        action = "$";
        desc = "move to last character of line";
      }
      {
        key = "<C-h>";
        mode = "n";
        action = "<C-w>h";
        desc = "switch to left pane";
      }
      {
        key = "<C-j>";
        mode = "n";
        action = "<C-w>j";
        desc = "switch to below pane";
      }
      {
        key = "<C-k>";
        mode = "n";
        action = "<C-w>k";
        desc = "switch to above pane";
      }
      {
        key = "<C-l>";
        mode = "n";
        action = "<C-w>l";
        desc = "switch to right pane";
      }
      {
        key = "<leader>tt";
        mode = "n";
        action = "<cmd>vs<cr><cmd>term<cr>";
        desc = "open a terminal in a vertical split";
      }
      {
        key = "<leader>qq";
        mode = "n";
        action = "<cmd>clo<cr>";
        desc = "close window";
      }
      {
        key = "<leader><esc><esc>";
        mode = "n";
        action = "<cmd>silent nohl<cr>";
        desc = "disable search highlight";
      }
    ];

    autocmds = [
      {
        event = [ "InsertEnter" ];
        callback = mkLuaInline ''
          function()
            vim.fn.clearmatches()
          end
        '';
        desc = "clear trailing whitespace matches on insert enter";
      }
      {
        event = [ "InsertLeave" ];
        callback = mkLuaInline ''
          function()
            vim.fn.matchadd("ws", [[\s\+$]])
          end
        '';
        desc = "highlight trailing whitespace on insert leave";
      }
      {
        event = [ "TextYankPost" ];
        callback = mkLuaInline ''
          function()
            vim.highlight.on_yank({ higroup = "Visual", timeout = 500 })
          end
        '';
        desc = "highlight yanked text";
      }
      {
        event = [ "VimResized" ];
        pattern = [ "*" ];
        callback = mkLuaInline ''
          function()
            vim.cmd("wincmd =")
          end
        '';
        desc = "auto-resize windows on vim resize";
      }
      {
        event = [ "BufWritePre" ];
        pattern = [ "*" ];
        command = "[[%s/\s\+$//e]]";
        desc = "remove trailing whitespace on save";
      }
    ];

    # initial lua config for whitespace highlighting
    luaConfigRC.whitespace = ''
      vim.api.nvim_set_hl(0, "ws", { bg = "red" })
      vim.fn.matchadd("ws", [[\s\+$]])
    '';
  };
}
