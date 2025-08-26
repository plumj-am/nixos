{ lib, ... }:
let
  inherit (lib) mkLuaInline;
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
      {
        event = [
          "BufRead"
          "BufNewFile"
        ];
        pattern = [
          "*.asm"
          "*.inc"
          "*.j"
        ];
        callback = mkLuaInline ''
                    function()
                      local lines = vim.api.nvim_buf_get_lines(0, 0, 40, false)
                      local content = table.concat(lines, "\n")
                      
                      if content:match("format ELF64 executable 3") then
                        vim.bo.filetype = "fasm"
          							vim.o.shiftwidth = 4
          							vim.o.tabstop = 4
          							vim.o.softtabstop = 4
          							vim.o.expandtab = true -- for nicer indentation
                      else
                        vim.bo.filetype = "nasm"
          							vim.o.shiftwidth = 4
          							vim.o.tabstop = 4
          							vim.o.softtabstop = 4
          							vim.o.expandtab = true -- for nicer indentation
                      end
                    end
        '';
        desc = "detect fasm vs nasm by format directive";
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
