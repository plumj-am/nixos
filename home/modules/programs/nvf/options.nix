{ lib, ... }:
let
  mkLuaInline = lib.generators.mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    enableLuaLoader = true;
    additionalRuntimePaths = [
      ./after
    ];
    extraLuaFiles = [
      (builtins.path {
        path = ./globals.lua;
      })
      (builtins.path {
        path = ./helpers.lua;
      })
      (builtins.path {
        path = ./set_colorscheme.lua;
      })
      (builtins.path {
        path = ./lsp.lua;
      })
    ];

    clipboard = {
      enable = true;
      registers = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    globals = {
      mapleader = " ";
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
      # missing from builtin ccc
      {
        key = "<leader>ccc";
        mode = "n";
        action = "<cmd>CccHighlighterToggle<CR>";
        desc = "Toggle ccc";
      }
      # missing from builtin mini.bufremove
      {
        key = "<leader>qb";
        mode = "n";
        action = "<cmd>lua MiniBufremove.delete()<CR>";
        desc = "close buffer";
      }
      # missing from builtin telescope
      {
        key = "<leader>ft";
        mode = "n";
        action = "<cmd>Telescope treesitter<CR>";
        desc = "Telescope treesitter";
      }
      {
        key = "<leader>fw";
        mode = "n";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<CR>";
        desc = "Telescope word";
      }
      {
        key = "<leader>fW";
        mode = "n";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<CR>";
        desc = "Telescope WORD";
      }
      {
        key = "<leader>fs";
        mode = "n";
        action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep > ') })<CR>";
        desc = "Telescope search for input word";
      }
      {
        key = "<leader>fc";
        mode = "n";
        action = "<cmd>lua require('telescope.builtin').resume()<CR>";
        desc = "Telescope resume last picker";
      }
      # missing from builtin undotree
      {
        key = "<leader>u";
        mode = "n";
        action = "<cmd>UndotreeToggle<CR>";
        desc = "Toggle undotree";
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
        command = "%s/\s\+$//e";
        desc = "remove trailing whitespace on save";
      }
      {
        event = [ "LspAttach" ];
        callback = mkLuaInline ''
          function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)

            vim.keymap.set("n", "<leader>ih", function()
              if vim.lsp.inlay_hint.is_enabled() then
                vim.lsp.inlay_hint.enable(false)
              else
                vim.lsp.inlay_hint.enable(true)
              end
            end)

            if client:supports_method("textDocument/foldingRange") then
              vim.wo.foldmethod = "expr"
              vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
            else
              vim.wo.foldmethod = "indent"
            end
            
            vim.keymap.set("n", "gd", function()
              vim.lsp.buf.definition()
            end, { desc = "Go to definition" })
            vim.keymap.set("n", "gr", function()
              vim.lsp.buf.references()
            end, { desc = "Show references" })
            vim.keymap.set("n", "grn", function()
              vim.lsp.buf.rename()
            end, { desc = "vim.lsp rename" })
            vim.keymap.set("n", "gi", function()
              vim.lsp.buf.implementation()
            end, { desc = "vim.lsp implementation" })
            vim.keymap.set({ "n", "v" }, "ga", function()
              vim.lsp.buf.code_action()
            end, { desc = "vim.lsp code action" })
            vim.keymap.set("n", "K", function()
              vim.lsp.buf.hover()
            end, { desc = "Hover" })
          end
        '';
      }
    ];

    # initial lua config for whitespace highlighting
    luaConfigRC.whitespace = ''
      vim.api.nvim_set_hl(0, "ws", { bg = "red" })
      vim.fn.matchadd("ws", [[\s\+$]])
    '';
  };
}
