{ lib, ... }:
let
  mkLuaInline = lib.generators.mkLuaInline;
in
{
  programs.nvf.settings.vim = {
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
    ];

    # TODO: fix not displaying red
    # initial lua config for whitespace highlighting
    luaConfigRC.whitespace = ''
      vim.api.nvim_set_hl(0, "ws", { bg = "red" })
      vim.fn.matchadd("ws", [[\s\+$]])
    '';
  };
}

