{ pkgs, ... }:
{
  programs.nvf.settings.vim = {

    assistant = {
      supermaven-nvim = {
        enable = true;
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
      rust = {
        crates.enable = true;
        dap.enable = true;
      };

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

    autocomplete = {
      blink-cmp = {
        enable = true;
        setupOpts = {
          keymap = {
            preset = "enter";
          };
          completion = {
            documentation = {
              auto_show = true;
              auto_show_delay_ms = 250;
            };
            # menu = {
            # draw = {
            # columns = {
            # { "kind" };
            # { "label", gap = 1 };
            # };
            # };
            # };
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
                opts = {
                  # get_bufnrs = function()
                  # 	return vim.tbl_filter(function(bufnr)
                  # 		return vim.bo[bufnr].buftype == ""
                  # 	end, vim.api.nvim_list_bufs())
                  # end,
                };
              };
            };
          };
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
          sql = [ "sql_formatter" ];
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

    # git integration
    # git = {
    # enable = false; # disabled initially
    # gitsigns.enable = true;
    # };

    # statusline
    # statusline = {
    # enable = false; # disabled initially
    # lualine.enable = true;
    # };

    lazy.plugins = {

      "SchemaStore.nvim" = {
        package = pkgs.vimPlugins.SchemaStore-nvim;
      };

      "dirbuf.nvim" = {
        package = pkgs.vimPlugins.dirbuf-nvim;
        cmd = "Dirbuf";
        setupModule = "dirbuf";
        setupOpts = {
          sort_order = "directories_first";
          write_cmd = "DirbufSync -confirm";
          show_hidden = true;
        };
        keys = [
          {
            mode = "n";
            key = "-";
            action = ":Dirbuf<CR>";
            desc = "Open dirbuf";
          }
          {
            mode = "n";
            key = "<C-s>";
            action = ":lua ToggleDirbuf()<CR>";
            desc = "Open dirbuf";
          }
        ];
      };

      "no-neck-pain.nvim" = {
        # doesnt load on startup idk why
        package = pkgs.vimPlugins.no-neck-pain-nvim;
        lazy = false;
        priority = 1001;
        setupOpts = {
          width = 110;
          autocmds = {
            enableOnVimEnter = true;
            skipEnteringNoNeckPainBuffer = true;
          };
          buffers = {
            wo = {
              fillchars = "eob: ";
            };
          };
        };
      };

      "vimplugin-pomo.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "pomo.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "epwalsh";
            repo = "pomo.nvim";
            rev = "aa8decc421d89be0f10b1fc6a602cdd269f350ff";
            sha256 = "sha256-tJ2TrypKnCnQm+6FDjX0KDr+UNoBBVvGIm+uWJtpNLc=";
          };
        };
        cmd = [
          "TimerStart"
          "TimerRepeat"
          "TimerSession"
        ];
        setupModule = "pomo";
        setupOpts = {
          update_interval = 500;
          sessions = {
            pomodoro = [
              {
                name = "Work";
                duration = "25m";
              }
              {
                name = "Break";
                duration = "5m";
              }
              {
                name = "Work";
                duration = "25m";
              }
              {
                name = "Break";
                duration = "5m";
              }
              {
                name = "Work";
                duration = "25m";
              }
              {
                name = "Break";
                duration = "15m";
              }
            ];
          };
          notifiers = [
            {
              name = "Default";
              opts = {
                sticky = false;
              };
            }
          ];
        };
      };

      "vimplugin-scrolleof.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "scrolleof.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "Aasim-A";
            repo = "scrollEOF.nvim";
            rev = "master";
            sha256 = "sha256-hHoS5WgIsbuVEOUbUBpDRxIwdNoR/cAfD+hlBWzaxug=";
          };
        };
        event = [ "WinScrolled" ];
        setupModule = "scrollEOF";
        setupOpts = { };
      };

      "vimplugin-tiny-inline-diagnostic.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "tiny-inline-diagnostic.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "rachartier";
            repo = "tiny-inline-diagnostic.nvim";
            rev = "7dcf8542059fb15c978de845fc8665428ae13a04";
            sha256 = "sha256-BGmGYYNweelepgFQ58X2PhafAHNyb0N+nNqncHU0Kbc=";
          };
        };
        event = [ "BufReadPost" ];
        setupModule = "tiny-inline-diagnostic";
        setupOpts = {
          preset = "minimal";
          transparent_bg = true;
          transparent_cursorline = false;
          signs = {
            arrow = "";
            up_arrow = "";
          };
          options = {
            show_source = {
              enabled = true;
            };
            multilines = {
              enabled = true;
              always_show = true;
            };
            throttle = 100;
          };
        };
      };

      "vimplugin-package-info.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "package-info.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "vuki656";
            repo = "package-info.nvim";
            rev = "4f1b8287dde221153ec9f2acd46e8237d2d0881e";
            sha256 = "sha256-vrRcWSPfWTDs0r7LvqJVMIPFSZTlLJQG1/dU5or6xLs=";
          };
          doCheck = false;
        };
        event = [ "BufRead package.json" ];
        setupModule = "package-info";
        setupOpts = {
          autostart = true;
          hide_unstable_versions = true;
          notifications = false;
          icons = {
            enable = true;
            style = {
              up_to_date = "   ";
              outdated = "   ";
              invalid = "   ";
            };
          };
        };
        after = ''
          vim.api.nvim_set_hl(0, "PackageInfoUpToDateVersion", { fg = "#3c4048" })
          vim.api.nvim_set_hl(0, "PackageInfoOutdatedVersion", { fg = "#d19a66" })
          vim.api.nvim_set_hl(0, "PackageInfoInvalidVersion", { fg = "#ee4b2b" })
          vim.cmd("lua require('package-info').show({ force = true })")
        '';
      };

      "nui.nvim" = {
        package = pkgs.vimPlugins.nui-nvim;
        lazy = true;
      };

      "vimplugin-ts-context-commentstring.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "ts-context-commentstring.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "JoosepAlviste";
            repo = "nvim-ts-context-commentstring";
            rev = "1b212c2eee76d787bbea6aa5e92a2b534e7b4f8f";
            sha256 = "sha256-AjDM3+n4+lNBQi8P2Yrh0Ab06uYCndBQT9TX36rDbOM=";
          };
        };
        event = [ "BufRead" ];
        setupModule = "ts_context_commentstring";
        setupOpts = { };
      };

      "vimplugin-vimwiki" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "vimwiki";
          src = pkgs.fetchFromGitHub {
            owner = "vimwiki";
            repo = "vimwiki";
            rev = "72792615e739d0eb54a9c8f7e0a46a6e2407c9e8";
            sha256 = "sha256-O85nZUWxIKm0gFILAkWH9WqfVcEbnbxR56grqMmum3A=";
          };
        };
        keys = [
          {
            mode = "n";
            key = "<leader>ww";
            action = "<Plug>VimwikiIndex";
            desc = "Open vimwiki index";
          }
          {
            mode = "n";
            key = "<leader>wi";
            action = "<Plug>VimwikiDiaryIndex";
            desc = "Open vimwiki diary";
          }
        ];
        beforeAll = ''
          vim.g.vimwiki_option_diary_path = "./diary/"
          vim.g.vimwiki_global_ext = 0
          vim.g.vimwiki_option_nested_syntaxes = { svelte = "svelte", typescript = "ts" }
          vim.g.vimwiki_list = {
            { path = "~/vimwiki/james/", syntax = "markdown", ext = ".md" },
            { path = "~/vimwiki/healgorithms/", syntax = "markdown", ext = ".md" }
          }
        '';
      };

      "vimplugin-workspaces.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "workspaces.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "natecraddock";
            repo = "workspaces.nvim";
            rev = "55a1eb6f5b72e07ee8333898254e113e927180ca";
            sha256 = "sha256-a3f0NUYooMxrZEqLer+Duv6/ktq5MH2qUoFHD8z7fZA=";
          };
        };
        cmd = [ "Telescope workspaces" ];
        setupModule = "workspaces";
        setupOpts = {
          auto_open = true;
        };
        keys = [
          {
            mode = "n";
            key = "<leader>fp";
            action = ":Telescope workspaces<CR>";
            desc = "Open workspaces";
          }
        ];
        after = ''
          require("telescope").load_extension("workspaces")
        '';
      };

      "vimplugin-zen-mode.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "zen-mode.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "zen-mode.nvim";
            rev = "main";
            sha256 = "sha256-TofQ1o5+LH3/1aoLr90oLbBaXFFtu62SXifH5oyj2/k=";
          };
        };
        cmd = [ "ZenMode" ];
        setupModule = "zen-mode";
        setupOpts = {
          window = {
            backdrop = 0.95;
            width = 80;
            height = 1;
            options = {
              signcolumn = "no";
              number = false;
              relativenumber = false;
              cursorline = false;
              cursorcolumn = false;
              foldcolumn = "0";
              list = false;
            };
          };
          plugins = {
            options = {
              enabled = true;
              ruler = false;
              showcmd = true;
              laststatus = 0;
            };
            twilight = {
              enabled = true;
            };
            gitsigns = {
              enabled = false;
            };
          };
          on_open = "function() vim.opt.colorcolumn = '' end";
        };
      };

      "vimplugin-twilight.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "twilight.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "folke";
            repo = "twilight.nvim";
            rev = "main";
            sha256 = "sha256-sC9DSgkQw+jHvi+xUP+iWSSLV0kIWWmrom2Mq5q+RJo=";
          };
        };
        cmd = [ "Twilight" ];
        setupModule = "twilight";
        setupOpts = {
          dimming = {
            alpha = 0.4;
          };
        };
      };

      "vimplugin-typr" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "typr";
          src = pkgs.fetchFromGitHub {
            owner = "nvzone";
            repo = "typr";
            rev = "main";
            sha256 = "sha256-ULjrPOYaWCk8G5B37p+aYD0jI2vngc0LxQIxQduaEWo=";
          };
          doCheck = false;
        };
        cmd = [
          "Typr"
          "TyprStats"
        ];
        setupModule = "typr";
        setupOpts = {
          on_attach = "function() vim.opt_local.wrap = false; vim.opt_local.complete = '' end";
        };
      };

      "vimplugin-screenkey.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "screenkey.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "NStefan002";
            repo = "screenkey.nvim";
            rev = "main";
            sha256 = "sha256-94bafW0DP4Q9jfE4voiEvUy13JVTs6UP5qgLG2SbeZk=";
          };
        };
        cmd = [ "Screenkey" ];
        setupModule = "screenkey";
        setupOpts = {
          win_opts = {
            row = "vim.o.lines - 3";
            col = "vim.o.columns - 25";
            relative = "editor";
            anchor = "SE";
            width = 25;
            height = 1;
            border = "single";
            title = "Key";
            title_pos = "center";
            style = "minimal";
            focusable = false;
            noautocmd = true;
          };
          compress_after = 3;
          clear_after = 5;
          disable = {
            filetypes = [ ];
            buftypes = [ ];
          };
          show_leader = true;
          group_mappings = true;
          display_infront = [ ];
          display_behind = [ ];
          filter = "function(keys) return keys end";
          keys = {
            "<TAB>" = "󰌒";
            "<CR>" = "󰌑";
            "<ESC>" = "Esc";
            "<SPACE>" = "󱁐";
            "<BS>" = "󰁮";
            "<DEL>" = "󰁮";
            "<LEFT>" = "";
            "<RIGHT>" = "";
            "<UP>" = "";
            "<DOWN>" = "";
            "<HOME>" = "Home";
            "<END>" = "End";
            "<PAGEUP>" = "PgUp";
            "<PAGEDOWN>" = "PgDn";
            "<INSERT>" = "Ins";
            "<F1>" = "󱊫";
            "<F2>" = "󱊬";
            "<F3>" = "󱊭";
            "<F4>" = "󱊮";
            "<F5>" = "󱊯";
            "<F6>" = "󱊰";
            "<F7>" = "󱊱";
            "<F8>" = "󱊲";
            "<F9>" = "󱊳";
            "<F10>" = "󱊴";
            "<F11>" = "󱊵";
            "<F12>" = "󱊶";
          };
        };
        after = ''
          vim.cmd("Screenkey")
        '';
      };

      "vimplugin-quicksnip.vim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "quicksnip.vim";
          src = pkgs.fetchFromGitHub {
            owner = "jamesukiyo";
            repo = "quicksnip.vim";
            rev = "5b9ccd6937f1172817c5e3054ec58d7f5281b94d";
            sha256 = "sha256-QMLEqx6PH4m0c0eYhLspjGin+UrdgwcV7a/MzfRPMtM=";
          };
        };
        cmd = [
          "SnipCurrent"
          "SnipPick"
        ];
        keys = [
          {
            mode = "n";
            key = "<leader>sp";
            action = ":SnipPick<CR>";
            desc = "Pick snippet";
          }
          {
            mode = "n";
            key = "<leader>sc";
            action = ":SnipCurrent<CR>";
            desc = "Current snippet";
          }
        ];
        beforeAll = ''
          vim.g.miniSnip_dirs = { "~/.vim/snippets" }
          vim.g.miniSnip_trigger = "<C-c>"
          vim.g.miniSnip_extends = {
            html = { "html", "javascript" },
            svelte = { "html", "javascript" },
            javascript = { "html" },
            typescript = { "html", "javascript" }
          }
        '';
      };

      "vimplugin-minisnip" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "minisnip";
          src = pkgs.fetchFromGitHub {
            owner = "Jorenar";
            repo = "miniSnip";
            rev = "79d863e1f8d5313ea36d045c3c067a55f3814ecd";
            sha256 = "sha256-OkF1COC3FykTYd3P/WpRAS0n0nxAPPazOytr698+6TI=";
          };
        };
        event = [ "InsertEnter" ];
      };

      "vimplugin-ferris.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "ferris.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "vxpm";
            repo = "ferris.nvim";
            rev = "main";
            sha256 = "sha256-spi5Fk7HghMyhi+TqcgxRj9ME6HyJnVGyFkP+mPM010=";
          };
        };
        ft = [ "rust" ];
        setupModule = "ferris";
        setupOpts = {
          create_commands = true;
          url_handler = "start";
        };
      };

      "vimplugin-darklight.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "darklight.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "eliseshaffer";
            repo = "darklight.nvim";
            rev = "main";
            sha256 = "sha256-/MdGhcZ0kQsAzDl02lJK4zMf/5fC5Md0iuvWrz0ZR6Q=";
          };
        };
        lazy = false;
        priority = 1000;
        setupModule = "darklight";
        setupOpts = {
          mode = "custom";
          light = "function() ColorMyPencils('light') end";
          dark = "function() ColorMyPencils('dark') end";
        };
      };

      "vimplugin-compile-mode.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "compile-mode.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "ej-shafran";
            repo = "compile-mode.nvim";
            rev = "main";
            sha256 = "sha256-T2l/lEOiO+X5TfAT1mcsyg307nktT+YxxlpbCloNLp4=";
          };
          doCheck = false;
        };
        cmd = [ "Compile" ];
        keys = [
          {
            mode = "n";
            key = "<leader>co";
            action = ":vert Compile<cr>";
            desc = "Compile";
          }
          {
            mode = "n";
            key = "<leader>cr";
            action = ":vert Recompile<cr>";
            desc = "Recompile";
          }
        ];
        beforeAll = ''
          vim.g.compile_mode = {
            baleia_setup = true,
            default_command = "",
            recompile_no_fail = true
          }
        '';
      };

      "plenary.nvim" = {
        package = pkgs.vimPlugins.plenary-nvim;
        lazy = true;
      };

      "vimplugin-baleia.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "baleia.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "m00qek";
            repo = "baleia.nvim";
            rev = "v1.3.0";
            sha256 = "sha256-8wG9Oh5Ff7XXOjZ3rPvThCF5QYOyCXxiIcJjgT89RDU=";
          };
        };
        lazy = true;
      };

      "vimplugin-volt" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "volt";
          src = pkgs.fetchFromGitHub {
            owner = "nvzone";
            repo = "volt";
            rev = "main";
            sha256 = "sha256-szq/QBI2Y6DKeqBuJ8qA4LlGYnarLT6D/fvwepIgSVc=";
          };
        };
        lazy = true;
      };
    };
  };
}
