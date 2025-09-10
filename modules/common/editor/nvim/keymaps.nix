{ lib, ... }:
let
  inherit (lib) mkLuaInline;
in
{
  programs.nvf.settings.vim.keymaps = [
    # debugging
    {
      desc   = "toggle breakpoint";
      key    = "<leader>db";
      mode   = "n";
      action = ":lua require('dap').toggle_breakpoint()<CR>";
    }
    {
      desc   = "toggle breakpoint";
      key    = "<F1>";
      mode   = "n";
      action = ":lua require('dap').toggle_breakpoint()<CR>";
    }
    {
      desc   = "run last";
      key    = "<leader>dB";
      mode   = "n";
      action = ":lua require('dap').toggle_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>";
    }
    {
      desc   = "run last";
      key    = "<F2>";
      mode   = "n";
      action = ":lua require('dap').toggle_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>";
    }
    {
      desc   = "continue";
      key    = "<leader>dc";
      mode   = "n";
      action = ":lua require('dap').continue()<CR>";
    }
    {
      desc   = "continue";
      key    = "<F3>";
      mode   = "n";
      action = ":lua require('dap').continue()<CR>";
    }
    {
      desc   = "open/close debugger ui";
      key    = "<leader>du";
      mode   = "n";
      action = ":lua require('dapui').toggle()<CR>";
    }
    {
      desc   = "open/close debugger ui";
      key    = "<F4>";
      mode   = "n";
      action = ":lua require('dapui').toggle()<CR>";
    }
    {
      desc   = "step over";
      key    = "<leader>do";
      mode   = "n";
      action = ":lua require('dap').step_over()<CR>";
    }
    {
      desc   = "step over";
      key    = "<RIGHT>";
      mode   = "n";
      action = ":lua require('dap').step_over()<CR>";
    }
    {
      desc   = "step into";
      key    = "<leader>di";
      mode   = "n";
      action = ":lua require('dap').step_into()<CR>";
    }
    {
      desc   = "step into";
      key    = "<DOWN>";
      mode   = "n";
      action = ":lua require('dap').step_into()<CR>";
    }
    {
      desc   = "step out";
      key    = "<leader>dO";
      mode   = "n";
      action = ":lua require('dap').step_out()<CR>";
    }
    {
      desc   = "step out";
      key    = "<UP>";
      mode   = "n";
      action = ":lua require('dap').step_out()<CR>";
    }
    {
      desc   = "step back";
      key    = "<leader>dp";
      mode   = "n";
      action = ":lua require('dap').step_back()<CR>";
    }
    {
      desc   = "step back";
      key    = "<LEFT>";
      mode   = "n";
      action = ":lua require('dap').step_back()<CR>";
    }
    {
      desc   = "restart last session";
      key    = "<leader>dr";
      mode   = "n";
      action = ":lua require('dap').run_last()<CR>";
    }
    {
      desc   = "restart last session";
      key    = "<F5>";
      mode   = "n";
      action = ":lua require('dap').run_last()<CR>";
    }
    # clipboard mappings (thanks primeagen)
    {
      desc   = "paste over text but keep clipboard";
      key    = "<leader>p";
      mode   = "x";
      action = ''"_dP'';
    }
    {
      desc   = "yank selection to system clipboard";
      key    = "<leader>y";
      mode   = [ "n" "v" ];
      action = ''"+y'';
    }
    {
      desc   = "yank line to system clipboard";
      key    = "<leader>Y";
      mode   = "n";
      action = ''"+Y'';
    }
    {
      desc   = "delete without yank";
      key    = "<leader>d";
      mode   = [ "n" "v" ];
      action = ''"_d'';
    }
    {
      desc   = "better line joins";
      key    = "J";
      mode   = "n";
      action = "mzJ`z";
    }
    {
      desc   = "move line down";
      key    = "J";
      mode   = "v";
      action = ":m '>+1<CR>gv=gv";
    }
    {
      desc   = "move line up";
      key    = "K";
      mode   = "v";
      action = ":m '<-2<CR>gv=gv";
    }
    {
      desc   = "instant search and replace current word";
      mode   = "n";
      key    = "<leader>sr";
      action = '':%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>'';
    }
    {
      desc   = "1/2 page down + center cursor";
      key    = "<C-d>";
      mode   = "n";
      action = "<C-d>zz";
    }
    {
      desc   = "1/2 page up + center cursor";
      key    = "<C-u>";
      mode   = "n";
      action = "<C-u>zz";
    }
    {
      desc   = "center cursor on next search result";
      key    = "n";
      mode   = "n";
      action = "nzz";
    }
    {
      desc   = "center cursor on previous search result";
      key    = "N";
      mode   = "n";
      action = "Nzz";
    }
    {
      desc   = "1/2 page down + center cursor";
      key    = "<C-d>";
      mode   = "v";
      action = "<C-d>zz";
    }
    {
      desc   = "1/2 page up + center cursor";
      key    = "<C-u>";
      mode   = "v";
      action = "<C-u>zz";
    }
    {
      desc   = "center cursor on next search result";
      key    = "n";
      mode   = "v";
      action = "nzz";
    }
    {
      desc   = "center cursor on previous search result";
      key    = "N";
      mode   = "v";
      action = "Nzz";
    }
    {
      desc   = "move to first non-blank character of line";
      key    = "H";
      mode   = "n";
      action = "^";
    }
    {
      desc   = "move to last character of line";
      key    = "L";
      mode   = "n";
      action = "$";
    }
    {
      desc   = "switch to left pane";
      key    = "<C-h>";
      mode   = "n";
      action = "<C-w>h";
    }
    {
      desc   = "switch to below pane";
      key    = "<C-j>";
      mode   = "n";
      action = "<C-w>j";
    }
    {
      desc   = "switch to above pane";
      key    = "<C-k>";
      mode   = "n";
      action = "<C-w>k";
    }
    {
      desc   = "switch to right pane";
      key    = "<C-l>";
      mode   = "n";
      action = "<C-w>l";
    }
    {
      desc   = "open a terminal in a vertical split";
      key    = "<leader>tt";
      mode   = "n";
      action = "<cmd>vs<cr><cmd>term<cr>";
    }
    {
      desc   = "close window";
      key    = "<leader>qq";
      mode   = "n";
      action = "<cmd>clo<cr>";
    }
    {
      desc   = "disable search highlight";
      key    = "<leader><esc><esc>";
      mode   = "n";
      action = "<cmd>silent nohl<cr>";
    }
    # missing from builtin ccc
    {
      desc   = "Toggle ccc";
      key    = "<leader>ccc";
      mode   = "n";
      action = "<cmd>CccHighlighterToggle<CR>";
    }
    # missing from builtin mini.bufremove
    {
      desc   = "close buffer";
      key    = "<leader>qb";
      mode   = "n";
      action = "<cmd>lua MiniBufremove.delete()<CR>";
    }
    # telescope
    {
      desc   = "Telescope word";
      key    = "<leader>fw";
      mode   = "n";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cword>') })<CR>";
    }
    {
      desc   = "Telescope WORD";
      key    = "<leader>fW";
      mode   = "n";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.expand('<cWORD>') })<CR>";
    }
    {
      desc   = "Telescope search for input word";
      key    = "<leader>fs";
      mode   = "n";
      action = "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep > ') })<CR>";
    }
    # missing from builtin undotree
    {
      desc   = "Toggle undotree";
      key    = "<leader>u";
      mode   = "n";
      action = "<cmd>UndotreeToggle<CR>";
    }
    {
      desc   = "Open ~/notes/todo.md";
      key    = "<leader>td";
      mode   = "n";
      action = "<cmd>lua OpenTodo()<CR>";
    }
  ];

  programs.nvf.settings.vim.autocmds = [
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
}
