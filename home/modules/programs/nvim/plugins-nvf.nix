{ pkgs, lib, ... }:
{
  programs.nvf.settings.vim = {

    assistant = {
      supermaven-nvim = {
        enable = true;
        setupOpts = {
          keymaps = {
            accept_suggestion = "<TAB>";
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
        theme = "auto";
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

    lsp = {
      trouble = {
        enable = true;
        mappings = {
          quickfix = "<leader>tq";
          documentDiagnostics = "<leader>tr";
          workspaceDiagnostics = "<leader>te";
        };
        setupOpts = {
          auto_close = true;
          modes = {
            diagnostics = {
              win = {
                size = 0.3;
              };
            };
          };
        };
      };
    };

    # treesitter
    treesitter = {
      enable = true;
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        javascript
        typescript
        svelte
        markdown
        css
        html
        lua
        vim
        json
        yaml
        vimdoc
        go
        http
        nu
        rust
      ];
      fold = true;
      indent.enable = true;
      highlight.enable = true;
      textobjects.enable = true;
      # autoTagHtml = true;
      context = {
        enable = true;
        setupOpts = {
          max_lines = 3;
          separator = "-";
        };
      };
    };

    languages = {
      # rust = {
      #   crates.enable = true;
      #   dap.enable = true;
      # };

      markdown.extensions.render-markdown-nvim = {
        enable = true;
        setupOpts = {
          completions = {
            blink = {
              enabled = true;
            };
          };
          file_types = [ "markdown" ];
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
          selection_caret = "";
          color_devicons = true;
          layout_config = {
            horizontal = {
              prompt_position = "top";
              preview_width = 0.6;
            };
          };
          path_display = [ "truncate" ];
          sorting_strategy = "ascending";
          dynamic_preview_title = true;
        };
        extensions = {
          workspaces = { };
        };
      };
      mappings = {
        findFiles = "<leader>ff";
        liveGrep = "<leader>fg";
        buffers = "<leader>fb";
      };
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

    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          astro = [
            "prettierd"
            "prettier"
          ];
          go = [
            "gofumpt"
            "goimports"
          ];
          javascript = [
            "prettierd"
            "prettier"
          ];
          javascriptreact = [
            "prettierd"
            "prettier"
          ];
          typescript = [
            "prettierd"
            "prettier"
          ];
          typescriptreact = [
            "prettierd"
            "prettier"
          ];
          json = [
            "prettierd"
            "prettier"
          ];
          svelte = [
            "prettierd"
            "prettier"
          ];
          vue = [
            "prettierd"
            "prettier"
          ];
          yaml = [
            "prettierd"
            "prettier"
          ];
          md = [ "dprint" ];
          toml = [ "dprint" ];
          lua = [ "stylua" ];
          sql = [ "sleek" ];
          python = [ "ruff_format" ];
          rust = [ "rustfmt" ];
          # nu = [ "nufmt" ];
          nix = [ "nixfmt" ];
        };
        format_after_save = {
          async = true;
          # lsp_format = "fallback"
        };
      };
    };
  };
}
