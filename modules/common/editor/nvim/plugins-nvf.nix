{ pkgs, lib, ... }:
let
  inherit (lib) enabled disabled mkLuaInline;
in
{
  programs.nvf.settings.vim = {

    assistant.supermaven-nvim = enabled {
      setupOpts.keymaps.accept_word       = "<RIGHT>";
      setupOpts.keymaps.accept_suggestion = "<TAB>";
    };

    autocomplete.blink-cmp = enabled {
      mappings.next           = null;
      mappings.previous       = null;
      mappings.scrollDocsDown = "<C-d>";
      mappings.scrollDocsUp   = "<C-u>";

      setupOpts = {
        keymap.preset = "enter";
        completion = {
          list.selection.preselect = false;

          documentation.window.winhighlight = "FloatBorder:None,Search:None";

          menu.winhighlight = "FloatBorder:None,Search:None";
          menu.draw.columns = mkLuaInline ''
              {
                { "kind" },
                { "label", gap = 1 }
              }
            '';
        };
        cmdline.enabled   = false;
        signature.enabled = true;

        sources.providers.buffer.opts = mkLuaInline ''
          {
            get_bufnrs = function()
              return vim.tbl_filter(function(bufnr)
                return vim.bo[bufnr].buftype == ""
              end, vim.api.nvim_list_bufs())
            end,
          }
        '';
      };
    };

    statusline.lualine =
    let
      sections = {
        a = [ ''{ "mode" }'' ];
        b = [ ''{ "branch" } '' ''{ "diagnostics", symbols = { error = "", warn = "", info = "", hint = "" } }'' ];
        c = [ ''{ "filename", show_filename_only = false, path = 1 }'' ''{ "diff" }'' ];
        x = [ ];
        y = [ ''{ "encoding" }'' ''{ "fileformat" }'' ''{ "filetype" }'' ];
        z = [ ''{ "location" }'' ];
      };
    in
    enabled {
      theme        = "gruvbox";
      globalStatus = false;

      componentSeparator.left  = "";
      componentSeparator.right = "";
      sectionSeparator.left    = "";
      sectionSeparator.right   = "";

      setupOpts.options.disabled_filetypes = [ "no-neck-pain" "dapui_watches" "dapui_scopes" "dapui_breakpoints" "dapui_stacks" "dap-repl" "dapui_console" ];

      activeSection   = sections;
      inactiveSection = sections;
    };

    autopairs.nvim-autopairs = enabled;

    mini.ai = enabled;

    mini.surround = enabled;

    mini.bufremove = enabled;

    mini.diff = enabled {
      setupOpts = {
        view.style = "number";

        mappings.apply      = "";
        mappings.reset      = "";
        mappings.textobject = "";
        mappings.goto_first = "";
        mappings.goto_prev  = "";
        mappings.goto_next  = "";
        mappings.goto_last  = "";
      };
    };

    git.neogit = enabled {
      mappings.open = "<leader>g";
      setupOpts = {
        integrations.telescope = true;
        integrations.diffview  = true;

        commit_editor.staged_diff_split_kind = "vsplit";
        commit_select_view.kind              = "vsplit";
      };
    };

    navigation.harpoon = disabled {
      mappings.file1 = "<leader>h";
      mappings.file2 = "<leader>j";
      mappings.file3 = "<leader>k";
      mappings.file4 = "<leader>l";

      setupOpts.defaults = {
        save_on_toggle   = true;
        save_on_ui_close = true;
      };
    };

    utility.ccc = enabled;

    utility.diffview-nvim = enabled; # for neogit

    utility.undotree = enabled;

    utility.nvim-biscuits = enabled {
      setupOpts = {
        cursor_line_only = true;
        prefix_string    = " ";
        toggle_keybind   = "<leader>bi";
        show_on_start    = false;
      };
    };

    visuals.indent-blankline  = enabled;

    visuals.nvim-web-devicons = enabled;

    visuals.fidget-nvim = enabled {
      setupOpts = {
        progress.display.done_ttl        = 10;
        notification.override_vim_notify = true;
        notification.window.winblend     = 0;
        notification.window.zindex       = 1000;
        notification.window.max_width    = 60;
      };
    };

    telescope = enabled {
      setupOpts.defaults = {
        prompt_prefix         = " ";
        selection_caret       = " ";
        entry_prefix          = " ";
        dynamic_preview_title = true;
        color_devicons        = false;
        path_display          = [ "truncate" ];
        sorting_strategy      = "ascending";

        layout_config.horizontal.prompt_position = "top";
        layout_config.horizontal.preview_width   = 0.6;

        vimgrep_arguments = [ "rg" "--color=never" "--no-heading" "--with-filename" "--line-number" "--column" "--smart-case" "--hidden" ];
      };
      # rest are handled in ./keymaps.nix
      mappings.findFiles           = null; # now using fff
      mappings.findProjects        = null;
      mappings.diagnostics         = null;
      mappings.gitBranches         = null;
      mappings.gitBufferCommits    = null;
      mappings.gitCommits          = null;
      mappings.gitStash            = null;
      mappings.gitStatus           = null;
      mappings.helpTags            = null;
      mappings.lspDefinitions      = null;
      mappings.lspDocumentSymbols  = null;
      mappings.lspImplementations  = null;
      mappings.lspReferences       = null;
      mappings.lspTypeDefinitions  = null;
      mappings.lspWorkspaceSymbols = null;
      mappings.open                = null;
      mappings.liveGrep            = "<leader>fg";
      mappings.buffers             = "<leader>fb";
      mappings.treesitter          = "<leader>ft";
      mappings.resume              = "<leader>fc";
    };

    notes.todo-comments = enabled {
      setupOpts = {
        signs             = false;
        highlight.before  = "";
        highlight.keyword = "wide";
        highlight.after   = "";
      };
      mappings.telescope = "<leader>ftd";
    };
  };
}
