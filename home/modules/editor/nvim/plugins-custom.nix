{ pkgs, lib, ... }:
let
  inherit (lib) enabled;
in
{
  programs.nvf.settings.vim = {

    globals = {
      vimwiki_option_diary_path = "./diary/";
      vimwiki_global_ext = 0;
      vimwiki_option_nested_syntaxes = {
        svelte = "svelte";
        typescript = "ts";
      };
      vimwiki_list = [
        {
          path = "~/vimwiki/james/";
          syntax = "markdown";
          ext = ".md";
        }
        {
          path = "~/vimwiki/healgorithms/";
          syntax = "markdown";
          ext = ".md";
        }
      ];
      zenbones = {
        lightness = "bright";
        italic_strings = false;
      };
    };

    lazy.plugins = {

      "rustaceanvim" = {
        package = pkgs.vimPlugins.rustaceanvim;
        lazy = false;
      };

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

      "trouble.nvim" = {
        package = pkgs.vimPlugins.trouble-nvim;
        lazy = true;
        setupModule = "trouble";
        setupOpts = {
          auto_close = true;
          modes.diagnostics.win.size = 0.3;
        };
        keys = [
          {
            mode = "n";
            key = "<leader>tr";
            action = "<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>";
            desc = "Open trouble for current file";
          }
          {
            mode = "n";
            key = "<leader>te";
            action = "<cmd>Trouble diagnostics toggle focus=true<cr>";
            desc = "Open trouble for workspace";
          }
          {
            mode = "n";
            key = "<leader>tq";
            action = "<cmd>Trouble qflist toggle<cr>";
            desc = "Open trouble quickfix list";
          }
          {
            mode = "n";
            key = "<leader>tdq";
            action = "<cmd>TodoQuickFix<cr>";
            desc = "Open trouble quickfix list";
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
          buffers.wo.fillchars = "eob: ";
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
              opts.sticky = false;
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
            rev = "2575109749b4bf3a0bf979a17947b3c1e8c5137e";
            sha256 = "sha256-hHoS5WgIsbuVEOUbUBpDRxIwdNoR/cAfD+hlBWzaxug=";
          };
        };
        lazy = true;
        setupModule = "scrollEOF";
        setupOpts = { };
      };

      "tiny-inline-diagnostic.nvim" = {
        package = pkgs.vimPlugins.tiny-inline-diagnostic-nvim;
        setupModule = "tiny-inline-diagnostic";
        priority = 1000;
        lazy = false;
        setupOpts = {
          preset = "minimal";
          transparent_bg = true;
          transparent_cursorline = false;
          signs = {
            arrow = "";
            up_arrow = "";
          };
          options = {
            show_source.enabled = true;
            multilines = {
              enabled = true;
              always_show = true;
            };
            throttle = 100;
          };
        };
      };

      "package-info.nvim" = {
        package = pkgs.vimPlugins.package-info-nvim;
        lazy = true;
        setupModule = "package-info";
        setupOpts = {
          autostart = true;
          hide_unstable_versions = true;
          notifications = false;
          icons = enabled {
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

      "ts-comments.nvim" = {
        package = pkgs.vimPlugins.ts-comments-nvim;
        lazy = true;
      };

      "vimwiki" = {
        package = pkgs.vimPlugins.vimwiki;
        lazy = true;
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
      };

      "zen-mode.nvim" = {
        enabled = false;
        package = pkgs.vimPlugins.zen-mode-nvim;
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
            twilight.enabled = true;
            gitsigns.enabled = false;
          };
          on_open = "function() vim.opt.colorcolumn = '' end";
        };
      };

      "twilight.nvim" = {
        enabled = false;
        package = pkgs.vimPlugins.twilight-nvim;
        cmd = [ "Twilight" ];
        setupModule = "twilight";
        setupOpts.dimming.alpha = 0.4;
      };

      "typr" = {
        enabled = false;
        package = pkgs.vimPlugins.nvzone-typr;
        cmd = [
          "Typr"
          "TyprStats"
        ];
        setupModule = "typr";
        setupOpts.on_attach = "function() vim.opt_local.wrap = false; vim.opt_local.complete = '' end";
      };

      "vimplugin-screenkey.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "screenkey.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "NStefan002";
            repo = "screenkey.nvim";
            rev = "363730221a97bd4199beb878c54aa75facfe0dfe";
            sha256 = "sha256-lu2LuBgBPSeJuQn2H63Sz2UhE7Nz6KEQS9N6aEg88tE=";
          };
        };
        cmd = [ "Screenkey" ];
        enabled = false;
        setupModule = "screenkey";
        setupOpts = {
          win_opts = {
            row = "vim.o.lines - 3";
            col = "vim.o.columns - 25";
            relative = "editor";
            anchor = "SE";
            width = 25;
            height = 1;
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
        lazy = true;
      };

      "vimplugin-darklight.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "darklight.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "eliseshaffer";
            repo = "darklight.nvim";
            rev = "5db97e2d132ebdf32c7e5edb5b0c68be9ae43038";
            sha256 = "sha256-/MdGhcZ0kQsAzDl02lJK4zMf/5fC5Md0iuvWrz0ZR6Q=";
          };
        };
        lazy = true;
        setupModule = "darklight";
        setupOpts = {
          mode = "custom";
          light = "function() ColorMyPencils('gruvbox-material', 'light', false) end";
          dark = "function() ColorMyPencils('gruvbox-material', 'dark', false) end";
        };
      };

      "vimplugin-compile-mode.nvim" = {
        package = pkgs.vimUtils.buildVimPlugin {
          name = "compile-mode.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "ej-shafran";
            repo = "compile-mode.nvim";
            rev = "d436d8f11f156de619baba72cd1fbc4216586cd6";
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

      "smear-cursor.nvim" = {
        package = pkgs.vimPlugins.smear-cursor-nvim;
        lazy = false;
        setupModule = "smear_cursor";
        setupOpts = {
          stiffness = 0.8;
          trailing_stiffness = 0.6;
          damping = 0.95;
          distance_stop_animating = 0.5;
          # matrix_pixel_threshold = 0.5;
          never_draw_over_target = true;
          time_interval = 10;
          smear_between_buffers = true;
          smear_between_neighbor_lines = true;
          scroll_buffer_space = true;
          legacy_computing_symbols_support = false;
          smear_insert_mode = false;
          smear_to_cmd = false;
        };
      };

      "plenary.nvim" = {
        package = pkgs.vimPlugins.plenary-nvim;
        lazy = true;
      };

      "baleia.nvim" = {
        package = pkgs.vimPlugins.baleia-nvim;
        lazy = true;
      };

      "volt" = {
        package = pkgs.vimPlugins.nvzone-volt;
        lazy = true;
      };
    };
  };
}
