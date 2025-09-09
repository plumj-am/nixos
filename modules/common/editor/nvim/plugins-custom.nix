{ pkgs, lib, fenix, fff-nvim, ... }:
let
  inherit (lib) enabled;
in
{
  programs.nvf.settings.vim = {

    globals = {
      vimwiki_option_diary_path = "./diary/";
      vimwiki_global_ext        = 0;

      vimwiki_option_nested_syntaxes = {
        svelte     = "svelte";
        typescript = "ts";
      };

      vimwiki_list = [
        {
          path   = "~/vimwiki/james/";
          syntax = "markdown";
          ext    = ".md";
        }
        {
          path   = "~/vimwiki/healgorithms/";
          syntax = "markdown";
          ext    = ".md";
        }
      ];
      zenbones.lightness      = "bright";
      zenbones.italic_strings = false;
    };

    lazy.plugins = {

      "rustaceanvim" = {
        package = pkgs.vimPlugins.rustaceanvim;
        lazy = false;
      };

      "SchemaStore.nvim".package = pkgs.vimPlugins.SchemaStore-nvim;

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
          vim.g.miniSnip_dirs = { "~/nixos-config/modules/common/editor/nvim/snippets" }
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

      "fff.nvim" = {
        package = fff-nvim.packages.${pkgs.system}.fff-nvim;
				lazy = true;
				setupModule = "fff";
				setupOpts = {
					debug.enabled     = false;
					debug.show_scores = false;

					title  = "fff";
					prompt = " ";

					max_results = 1000;
					max_threads = 10;

					layout.prompt_position = "top";
					layout.preview_size    = 0.6;

					preview.show_file_info = false;

					hl.normal      = "Normal";
					hl.title       = "Normal";
					hl.border      = "Grey";
					hl.active_file = "TelescopeSelection";
					hl.cursor      = "Cursor";

				};
        keys = [
          {
            mode = "n";
            key = "<leader>ff";
            action = "<CMD>lua require('fff').find_files()<CR>";
            desc = "fff find_files";
          }
        ];
      };

			"lazyjj.nvim" = {
				package = pkgs.vimPlugins.lazyjj-nvim;
				lazy = true;
				setupModule = "lazyjj";
				keys = [
					{
						mode = "n";
						key = "<leader>jj";
						action = "<CMD>LazyJJ<CR>";
					}
				];
			};

      "plenary.nvim" = {
        package = pkgs.vimPlugins.plenary-nvim;
        lazy = true;
      };

      "baleia.nvim" = {
        package = pkgs.vimPlugins.baleia-nvim;
        lazy = true;
      };
    };
  };
}
