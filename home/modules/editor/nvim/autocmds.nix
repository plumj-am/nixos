{ lib, ... }:
let
  inherit (lib) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    autocmds = [
      {
				desc     = "clear trailing whitespace matches on insert enter";
        event    = [ "InsertEnter" ];
        callback = mkLuaInline ''
          function()
            vim.fn.clearmatches()
          end
        '';
      }
      {
				desc     = "highlight trailing whitespace on insert leave";
        event    = [ "InsertLeave" ];
        callback = mkLuaInline ''
          function()
            vim.fn.matchadd("ws", [[\(\s\|\r\)\+$]])
          end
        '';
      }
      {
				desc     = "highlight yanked text";
        event    = [ "TextYankPost" ];
        callback = mkLuaInline ''
          function()
            vim.highlight.on_yank({ higroup = "Visual", timeout = 500 })
          end
        '';
      }
      {
				desc     = "auto-resize windows on vim resize";
        event    = [ "VimResized" ];
        pattern  = [ "*" ];
        callback = mkLuaInline ''
          function()
            vim.cmd("wincmd =")
          end
        '';
      }
      {
				desc     = "remove trailing whitespace on save";
        event    = [ "BufWritePre" ];
        pattern  = [ "*" ];
        callback = mkLuaInline ''
          function()
            local cursor_pos = vim.api.nvim_win_get_cursor(0)
            vim.cmd("%s/\\(\\s\\|\\r\\)\\+$//e")
            vim.api.nvim_win_set_cursor(0, cursor_pos)
          end
        '';
      }
      {
        desc     = "detect fasm vs nasm by format directive";
        event    = [ "BufRead" "BufNewFile" ];
        pattern  = [ "*.asm" "*.inc" "*.j" ];
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
      }
    ];

    # initial lua config for whitespace highlighting
    luaConfigRC.whitespace = "
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = function()
          vim.api.nvim_set_hl(0, 'ws', { bg = 'red' })
        end
      })
      vim.api.nvim_set_hl(0, 'ws', { bg = 'red' })
      vim.fn.matchadd('ws', [[\(\s\|\r\)\+$]])
    ";
  };
}
