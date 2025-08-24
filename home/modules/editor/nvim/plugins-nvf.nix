{ pkgs, lib, ... }:
let
  inherit (lib) enabled;
in
{
  programs.nvf.settings.vim = {

    assistant = {
      supermaven-nvim = {
        enable = true;
        setupOpts = {
          keymaps = {
            accept_word = "<RIGHT>";
            accept_suggestion = "<TAB>";
          };
        };
      };
    };

    autocomplete.blink-cmp = enabled {
      mappings = {
        next = null;
        previous = null;
        scrollDocsDown = "<C-d>";
        scrollDocsUp = "<C-u>";
      };
      setupOpts = {
        keymap = {
          preset = "enter";
        };
        completion = {
          list = {
            selection = {
              preselect = false;
            };
          };
          documentation = {
            window = {
              border = "single";
              winhighlight = "Normal:Normal,FloatBorder:None,CursorLine:CursorLine,Search:None";
            };
            auto_show = true;
            auto_show_delay_ms = 250;
          };
          menu = {
            border = "single";
            winhighlight = "Normal:Normal,FloatBorder:None,CursorLine:CursorLine,Search:None";

            draw = {
              columns = lib.generators.mkLuaInline ''
                {
                  { "kind" },
                  { "label", gap = 1 }
                }
              '';
            };
          };
        };
        cmdline = {
          enabled = false;
        };
        signature = {
          enabled = true;
        };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          providers = {
            buffer = {
              opts = lib.generators.mkLuaInline ''
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
        };
      };
    };

    statusline = {
      lualine = {
        enable = true;
        globalStatus = false;
        componentSeparator.left = "";
        componentSeparator.right = "";
        sectionSeparator.left = "";
        sectionSeparator.right = "";
        setupOpts = {
          options = {
            disabled_filetypes = [
              "no-neck-pain"
              "dapui_watches"
              "dapui_scopes"
              "dapui_breakpoints"
              "dapui_stacks"
              "dap-repl"
              "dapui_console"
            ];
          };
        };
        theme = "gruvbox";
        icons.enable = true;
        activeSection = {
          a = [ ''{ "mode" }'' ];
          b = [
            ''{ "branch" } ''
            ''{ "diagnostics", symbols = { error = "", warn = "", info = "", hint = "" } }''
          ];
          c = [
            ''{ "filename", show_filename_only = false, path = 1 }''
            ''{ "diff" }''
          ];
          x = [ ''{ LualinePomoTimer }'' ];
          y = [
            # cant get LualineFileInfo to work :[
            ''{ "encoding" }''
            ''{ "fileformat" }''
            ''{ "filetype" }''
          ];
          z = [ ''{ "location" }'' ];
        };
        inactiveSection = {
          a = [ ''{ "mode" }'' ];
          b = [
            ''{ "branch" } ''
            ''{ "diagnostics", symbols = { error = "", warn = "", info = "", hint = "" } }''
          ];
          c = [
            ''{ "filename", show_filename_only = false, path = 1 }''
            ''{ "diff" }''
          ];
          x = [ ''{ LualinePomoTimer }'' ];
          y = [
            ''{ "encoding" }''
            ''{ "fileformat" }''
            ''{ "filetype" }''
          ];
          z = [ ''{ "location" }'' ];
        };
      };
    };

    autopairs = {
      nvim-autopairs = {
        enable = true;
        setupOpts = {
          disable_filetype = [ "typr" ];
        };
      };
    };

    mini = {
      ai.enable = true;
      diff = {
        enable = true;
        setupOpts = {
          view = {
            style = "number";
          };
          mappings = {
            apply = "";
            reset = "";
            textobject = "";
            goto_first = "";
            goto_prev = "";
            goto_next = "";
            goto_last = "";
          };
        };
      };
      surround.enable = true;
      bufremove.enable = true;
    };

    git = {
      neogit = {
        enable = true;
        mappings.open = "<leader>g";
        setupOpts = {
          integrations = {
            telescope = true;
            diffview = true;
          };
          commit_editor = {
            staged_diff_split_kind = "vsplit";
          };
          commit_select_view = {
            kind = "vsplit";
          };
        };
      };
    };

    navigation = {
      harpoon = {
        enable = false;
        mappings = {
          file1 = "<leader>h";
          file2 = "<leader>j";
          file3 = "<leader>k";
          file4 = "<leader>l";
        };
        setupOpts = {
          defaults = {
            save_on_toggle = true;
            save_on_ui_close = true;
          };
        };
      };
    };

    utility = {
      ccc.enable = true;
      diffview-nvim.enable = true; # for neogit
      undotree.enable = true;
      nvim-biscuits = {
        enable = true;
        setupOpts = {
          cursor_line_only = true;
          prefix_string = " ";
          toggle_keybind = "<leader>bi";
          show_on_start = false;
        };
      };
    };

    visuals = {
      indent-blankline.enable = true;
      nvim-web-devicons.enable = true;
      fidget-nvim = {
        enable = true;
        setupOpts = {
          progress = {
            display = {
              done_ttl = 10;
            };
          };
          notification = {
            override_vim_notify = true;
            window = {
              winblend = 0;
              zindex = 1000;
              max_width = 60;
            };
          };
        };
      };
    };

    telescope = {
      enable = true;
      setupOpts = {
        defaults = {
          prompt_prefix = " ";
          selection_caret = " ";
          entry_prefix = " ";
          color_devicons = false;
          layout_config = {
            horizontal = {
              prompt_position = "top";
              preview_width = 0.6;
            };
          };
          path_display = [ "truncate" ];
          sorting_strategy = "ascending";
          dynamic_preview_title = true;
          vimgrep_arguments = [
            "rg"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
            "--smart-case"
            "--hidden"
            # "--no-ignore"
          ];
        };
        extensions = {
          workspaces = { };
        };
      };
      # handled in ./keymaps.nix
      mappings = { };
    };

    notes = {
      todo-comments = {
        enable = true;
        setupOpts = {
          signs = false;
          highlight = {
            before = "";
            keyword = "wide";
            after = "";
          };
        };
        mappings = {
          telescope = "<leader>td";
        };
      };
    };
  };
}
