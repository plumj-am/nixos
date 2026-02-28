let
  disableNano = {
    programs.nano.enable = false;
  };

  helixBase =
    {
      inputs,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs' nameValuePair;
      inherit (lib.trivial) const;
      inherit (lib.attrsets)
        genAttrs
        optionalAttrs
        attrValues
        mapAttrs
        ;
      inherit (lib.lists) singleton;
      inherit (builtins) elem;
      inherit (config) theme;

      toml = pkgs.formats.toml { };

      yaziPickerScript =
        pkgs.writeShellScript "yazi-picker.sh" # bash
          ''
            #!/usr/bin/env bash

            paths=$(yazi "$2" --chooser-file=/dev/stdout | while read -r; do printf "%q " "$REPLY"; done)

            if [[ -n "$paths" ]]; then
            	zellij action toggle-floating-panes
            	zellij action write 27 # send <Escape> key
            	zellij action write-chars ":$1 $paths"
            	zellij action write 13 # send <Enter> key
            else
            	zellij action toggle-floating-panes
            fi
          '';

      mkFgStyle =
        colors: color:
        genAttrs colors (const {
          fg = color;
        });

      mkBgStyle =
        colors: color:
        genAttrs colors (const {
          bg = color;
        });

      mkThemes =
        themes:
        mapAttrs' (
          name: value:
          nameValuePair "helix/themes/${name}.toml" {
            source = toml.generate "helix-theme-${name}.toml" value;
          }
        ) themes;

      settings = {
        theme = if theme.colorScheme == "pywal" then "base16_custom" else theme.helix;

        editor = {
          bufferline = "multiple";
          completion-timeout = 5;
          completion-replace = true;
          color-modes = true;
          cursorline = true;
          file-picker.hidden = false;
          idle-timeout = 0;
          shell = [
            "nu"
            "--commands"
          ];
          trim-trailing-whitespace = true;
          true-color = true;
          lsp.display-inlay-hints = true;
          inline-diagnostics.cursor-line = "hint";
          end-of-line-diagnostics = "hint";
          jump-label-alphabet = "jfkdls;aurieowpqnvmcxz";
          cursor-shape = {
            normal = "block";
            select = "underline";
            insert = "bar";
          };
          indent-guides = {
            character = "▏";
            render = true;
          };
          whitespace = {
            characters.tab = "→";
            render.tab = "all";
          };

          auto-pairs = {
            "\"" = "\"";
            "'" = "'";
            "`" = "`";
            "(" = ")";
            "{" = "}";
            "[" = "]";
            "<" = ">";
          };

          # Nightly options:
          word-completion.trigger-length = 3;
          rainbow-brackets = false;
        };

        keys = {
          select = {
            "A-h" = "jump_view_left";
            "A-j" = "jump_view_down";
            "A-k" = "jump_view_up";
            "A-l" = "jump_view_right";

            "C-j" = "@X*dp";
            "C-k" = "@X*dkP";

            "ret" = "goto_word";

            "q" = "record_macro";
            "@" = "replay_macro";

            "C-X" = "select_line_above";

            "C-y" =
              ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- ${yaziPickerScript} open ...%{buffer_name}";

            "C-a" = "@*%s<ret>";

            "D" = "extend_to_line_end";
          };

          normal = {
            # Hack to have a custom popup helper with a title.
            "A-h" = "jump_view_left";
            "A-j" = "jump_view_down";
            "A-k" = "jump_view_up";
            "A-l" = "jump_view_right";

            # Move lines up and down. Use `z` register to avoid clobbering system or primary clipboard.
            "C-j" = "@X\"zd\"zp";
            "C-k" = "@X\"zdk\"zP";

            "ret" = "goto_word";

            "q" = "record_macro";
            "@" = "replay_macro";

            "C-X" = "select_line_above";

            "C-y" =
              ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- ${yaziPickerScript} open ...%{buffer_name}";

            "C-a" = "@*%s<ret>";

            "D" = "extend_to_line_end";

            "'" = {
              _ = "@ File Management\n";

              t = "@:sh touch <C-r>%";
              r = "@:sh rm <C-r>%";
              k = "@:sh mkdir <C-r>%";
              m = "@:sh mv <C-r>% <C-r>%";
              c = "@:sh cp <C-r>% <C-r>%";
            };

            # Like `ci<char>` in vim.
            m = {
              "(" = "@lf)hmi)";
              ")" = "@lf)hmi)";
              "{" = "@lf}hmi}";
              "}" = "@lf}hmi}";
              "[" = "@lf]hmi]";
              "]" = "@lf]hmi]";
              "'" = "@lf'lmi'";
              "\"" = "@lf\"lmi\"";
            };
          };
        };
      };

      # Pywal output doesn't have gradients like base16 needs.
      # So it's necessary to override a few colours.
      # Also added overrides for diagnostic colours which don't work well from Pywal.
      themes = {
        base16_custom = {
          inherits = "base16_default";
        }
        # Comments.
        // mkFgStyle [ "comment" ] (if theme.isDark then "#909090" else "#C0C0C0")
        # Selections.
        // mkBgStyle [ "ui.selection" "ui.selection.primary" ] (
          if theme.isDark then "#707070" else "#E0E0E0"
        )
        # Cursorline and popups.
        // mkBgStyle [ "ui.cursorline.primary" "ui.cursorline.secondary" "ui.popup" "ui.popup.info" ] (
          if theme.isDark then "#404040" else "#F0F0F0"
        )
        # Info.
        //
          mkFgStyle
            [ "hint" "info" "diagnostic" "diagnostic.hint" "diagnostic.info" "diagnostic.unnecessary" ]
            (
              if theme.isDark then "#2B83A6" else "#3A8C9A" # Muted teal.
            )
        # Warnings.
        // mkFgStyle [ "warning" "diagnostic.warning" "diagnostic.deprecated" ] (
          if theme.isDark then "#B58900" else "#9D8740" # Muted yellow.
        )
        # Errors.
        // mkFgStyle [ "error" "diagnostic.error" ] (
          if theme.isDark then "#9D0006" else "#8F3F71" # Muted red/brown.
        );
      };

      languages = {
        language =
          let
            denoFmtArgs = [
              "fmt"
              "--use-tabs"
              "--no-semicolons"
              "--indent-width"
              "4"
              "--unstable-component"
            ];

            denoJsTsLanguages = [
              "javascript"
              "jsx"
              "typescript"
              "tsx"
            ];

            languageConfig =
              name: extension:
              {
                inherit name;
                auto-format = true;
                formatter.command = "deno";
                formatter.args = denoFmtArgs ++ [
                  "--ext"
                  extension
                  "-"
                ];
              }
              // optionalAttrs (elem name denoJsTsLanguages) {
                language-servers = [
                  "deno"
                  "typos"
                ];
              };

            denoFmtLanguages =
              {
                astro = "astro";
                css = "css";
                html = "html";
                javascript = "js";
                json = "json";
                jsonc = "jsonc";
                jsx = "jsx";
                markdown = "md";
                scss = "scss";
                svelte = "svelte";
                tsx = "tsx";
                typescript = "ts";
                vue = "vue";
                yaml = "yaml";
              }
              |> mapAttrs languageConfig
              |> attrValues;

            baseLanguages = [
              {
                name = "rust";
                auto-format = true;
                language-servers = [
                  {
                    name = "rust-analyzer";
                    except-features = singleton "inlay-hints";
                  }
                  "typos"
                ];
                indent = {
                  tab-width = 3;
                  unit = "   ";
                };
              }
              {
                name = "nix";
                auto-format = true;
                formatter.command = "nixfmt";
                language-servers = [
                  "nixd"
                  "typos"
                ];
              }
              {
                name = "toml";
                auto-format = true;
                formatter.command = "taplo";
                formatter.args = [
                  "fmt"
                  "--option"
                  "align_entries=true"
                  "--option"
                  "column_width=100"
                  "--option"
                  "compact_arrays=false"
                  "--option"
                  "reorder_inline_tables=true"
                  "--option"
                  "reorder_keys=true"
                  "-"
                ];
                language-servers = [
                  "taplo"
                  "typos"
                ];
              }
              {
                name = "markdown";
                auto-format = true;
                language-servers = [
                  "marksman"
                  "typos"
                ];
              }
              {
                name = "just";
                auto-format = true;
                formatter.command = "just-formatter";
                language-servers = [
                  "just-lsp"
                  "typos"
                ];
              }
              {
                name = "nu";
                auto-format = false;
                # formatter.command = "nufmt"; # Not good enough yet.
                # formatter.args = [
                #   "--config"
                #   "/home/jam/.config/nufmt/config.nuon"
                #   "--stdin"
                # ];
                language-servers = [
                  "nu-lsp"
                  # "nu-lint" # Waiting for <https://codeberg.org/wvhulle/nu-lint/pulls/96>
                  "typos"
                ];
                indent = {
                  tab-width = 3;
                  unit = "   ";
                };
              }
              # I can't get this working right now.
              # {
              #   name               = "rust";
              #   debugger.name      = "lldb-dap";
              #   debugger.transport = "stdio";
              #   debugger.command   = "lldb-dap";
              #   debugger.templates = [{
              #     name         = "binary";
              #     request      = "launch";
              #     args.program = "{0}";
              #     completion   = [{
              #       name       = "binary";
              #       completion = "filename";
              #     }];
              #   }];
              # }
            ];
          in
          denoFmtLanguages ++ baseLanguages;

        language-servers = {
          nixd = {
            command = "nixd";
            args = singleton "--inlay-hints";
            config.nixd = {
              nixpkgs.expr = ''import (builtins.getFlake "/home/jam/nixos").inputs.os { }'';
              options = {
                current-host.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.${config.networking.hostName}.options'';
                flake-parts.expr = ''(builtins.getFlake "/home/jam/nixos").debug.options'';
                flake-parts2.expr = ''(builtins.getFlake "/home/jam/nixos").currentSystem.options'';
              };
            };
          };

          typos.command = "typos-lsp";

          deno = {
            command = "deno";
            args = singleton "lsp";

            config.javascript = {
              enable = true;
              lint = true;
              unstable = true;

              suggest.imports.hosts."https://deno.land" = true;

              inlayHints.enumMemberValues.enabled = true;
              inlayHints.functionLikeReturnTypes.enabled = true;
              inlayHints.parameterNames.enabled = "all";
              inlayHints.parameterTypes.enabled = true;
              inlayHints.propertyDeclarationTypes.enabled = true;
              inlayHints.variableTypes.enabled = true;
            };
          };

          rust-analyzer = {
            except-features = singleton "inlay-hints";

            config = {
              cargo.features = "all";
              check.command = "clippy";
              completion.callable.snippets = "add_parentheses";
            };
          };
        };
      };
    in
    {
      hjem.extraModules = singleton {
        packages = singleton inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.helix; # `.helix` follows the master branch.

        xdg.config.files = {
          "helix/config.toml".source = toml.generate "helix-config.toml" settings;

          "helix/languages.toml".source = toml.generate "helix-languages.toml" languages;

          "nufmt/config.nuon".text = # nuon
            ''
              {
                indent: 3
                line_length: 100
                margin: 1
              }
            '';
        }
        // mkThemes themes;
      };
    };

  zedBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.attrsets) mapAttrs;
      inherit (config.myLib) mkDesktopEntry;
      inherit (config) theme;

      json = pkgs.formats.json { };

      mkZedKeymap =
        context: bindings: if context == null then { inherit bindings; } else { inherit context bindings; };

      mkDenoFmt = ext: {
        external = {
          command = "deno";
          arguments = [
            "fmt"
            "--use-tabs"
            "--no-semicolons"
            "--indent-width=4"
            "--unstable-component"
            "--ext"
            ext
          ];
        };
      };

      denoJsTsLanguages = {
        JavaScript = "js";
        JSX = "jsx";
        TSX = "tsx";
        TypeScript = "ts";
      };

      zedConfig = with theme; {
        auto_update = false;
        base_keymap = "VSCode";
        helix_mode = true;
        load_direnv = "direct";
        cursor_blink = false;
        show_edit_predictions = false; # Annoying spam popups.
        vertical_scroll_margin = 6;
        horizontal_scroll_margin = 12;
        use_system_path_prompts = false;

        active_pane_modifiers = {
          inactive_opacity = 0.85;
          border_size = border.small;
        };

        terminal = {
          shell.program = "nu";
        };

        vim = {
          highlight_on_yank_duration = 500;
          use_smartcase_find = true;
          cursor_shape = {
            normal = "block";
            insert = "bar";
            replace = "underline";
            visual = "underline";
          };
        };

        command_aliases = {
          bc = "pane::CloseActiveItem";
          rl = "editor::ReloadFile";
          lspr = "editor::RestartLanguageServer";
          wn = "workspace::SaveWithoutFormat";
        };

        inlay_hints = {
          enabled = true;
          show_type_hints = true;
          show_parameter_hints = true;
          show_other_hints = true;
        };

        diagnostics = {
          inline.enabled = true;
        };

        tab_bar.show = false;

        tabs = {
          file_icons = true;
          show_diagnostics = "all";
        };

        git = {
          inline_blame.enabled = true;
        };

        project_panel = {
          default_width = 300;
          indent_size = 16;
          entry_spacing = "standard";
          starts_open = false;
        };

        which_key = {
          enabled = true;
          delay_ms = 0;
        };

        ui_font_family = font.sans.name;
        ui_font_size = font.size.medium;

        buffer_font_family = font.mono.name;
        buffer_font_size = font.size.medium;

        agent_ui_font_size = font.size.medium;
        agent_buffer_font_size = font.size.medium;

        theme = {
          mode = "system";
          dark = themes.zed.dark;
          light = themes.zed.light;
        };

        auto_install_extensions = {
          astro = true;
          cargotom = true;
          deno = true;
          haskell = true;
          ini = true;
          justfile = true;
          kdl = true;
          nix = true;
          nu = true;
          qml = false;
          rust = true;
          svelte = true;
          typos = true;

          opencode = true;
          context7 = true;

          jj-conflict-resolver = true;
        };

        search = {
          regex = true;
          center_on_match = true;
        };

        use_smartcase_search = true;

        search_on_input = true;

        seed_search_query_from_cursor = "selection";

        auto_signature_help = true;

        preview_tabs = {
          enable_preview_from_file_finder = true;
          enable_preview_from_project_panel = true;
          enabled = true;
        };

        document_folding_ranges = "on";

        gutter.runnables = false;

        agent.default_model = {
          provider = "zai";
          model = "glm-5";

        };

        language_models = {
          openai_compatible.zai = {
            api_url = "https://api.z.ai/api/coding/paas/v4";
            available_models = [
              {
                name = "glm-5";
                display_name = "GLM-5";
                max_tokens = 200000;
                max_output_tokens = 128000;
                max_completion_tokens = 128000;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                };
              }
              {
                name = "glm-4.7-flash";
                display_name = "GLM-4.7-FlashX";
                max_tokens = 200000;
                max_output_tokens = 128000;
                max_completion_tokens = 128000;
                capabilities = {
                  tools = true;
                  images = false;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                };
              }
            ];
          };
        };

        languages = {
          Nix = {
            language_servers = [
              "typos"
              "nixd"
              "!nil"
            ];

            formatter.external.command = "nixfmt";
          };

          Rust = {
            tab_size = 3;
            language_servers = [
              "typos"
              "rust-analyzer"
            ];
          };

          TOML = {
            language_servers = [
              "taplo"
              "typos"
            ];

            formatter.external = {
              command = "taplo";
              arguments = [
                "fmt"
                "--option"
                "align_entries=true"
                "--option"
                "column_width=100"
                "--option"
                "compact_arrays=false"
                "--option"
                "reorder_inline_tables=true"
                "--option"
                "reorder_keys=true"
                "{buffer_path}"
              ];
            };
          };

          Markdown = {
            language_servers = [
              "marksman"
              "typos"
            ];
            formatter = mkDenoFmt "md";
          };

          Just = {
            language_servers = [
              "just-lsp"
              "typos"
            ];

            formatter.external.command = "just-formatter";
          };

          Nu = {
            tab_size = 3;
            language_servers = [
              "nu-lsp"
              "typos"
            ];
          };

          Astro = {
            language_servers = [
              "typos"
              "astrols"
            ];

            formatter = mkDenoFmt "astro";
          };

          CSS = {
            language_servers = [
              "typos"
            ];

            formatter = mkDenoFmt "css";
          };

          SCSS = {
            language_servers = [
              "typos"
            ];

            formatter = mkDenoFmt "scss";
          };

          HTML = {
            language_servers = [
              "typos"
            ];

            formatter = mkDenoFmt "html";
          };

          JSON = {
            language_servers = [
              "typos"
              "jsonls"
            ];

            formatter = mkDenoFmt "json";
          };

          JSONC = {
            language_servers = [
              "typos"
              "jsonls"
            ];

            formatter = mkDenoFmt "jsonc";
          };

          Svelte = {
            language_servers = [
              "typos"
              "svelte-language-server"
            ];

            formatter = mkDenoFmt "svelte";
          };

          Vue = {
            language_servers = [
              "typos"
              "vuels"
            ];

            formatter = mkDenoFmt "vue";
          };

          YAML = {
            language_servers = [
              "typos"
              "yamlls"
            ];

            formatter = mkDenoFmt "yaml";
          };
        }
        // mapAttrs (_name: ext: {
          language_servers = [
            "deno"
            "!typescript-language-server"
            "!vtsls"
            "!eslint"
          ];

          formatter = mkDenoFmt ext;
        }) denoJsTsLanguages;

        lsp = {
          rust-analyzer = {
            initialization_options = {
              cargo.features = "all";
              procMacro.enable = true;
              check.command = "clippy";
              inlayHints.enable = null;
            };
          };

          nixd.binary.arguments = singleton "--inlay-hints";

          deno = {
            settings.javascript = {
              enable = true;
              lint = true;
              unstable = true;

              suggest.imports.hosts."https://deno.land" = true;

              inlayHints.enumMemberValues.enabled = true;
              inlayHints.functionLikeReturnTypes.enabled = true;
              inlayHints.parameterNames.enabled = "all";
              inlayHints.parameterTypes.enabled = true;
              inlayHints.propertyDeclarationTypes.enabled = true;
              inlayHints.variableTypes.enabled = true;
            };
          };
        };
      };

      zedKeymaps = [
        (mkZedKeymap null {
          ctrl-W = null;
          ctrl-q = null;
          ctrl-F = null;
          ctrl-P = null;
          ctrl-H = null;
          "ctrl-=" = "zed::ResetAllZoom";
          alt-h = "workspace::ActivatePaneLeft";
          alt-j = "workspace::ActivatePaneDown";
          alt-k = "workspace::ActivatePaneUp";
          alt-l = "workspace::ActivatePaneRight";
          alt-H = "vim::ResizePaneLeft";
          alt-J = "vim::ResizePaneDown";
          alt-K = "vim::ResizePaneUp";
          alt-L = "vim::ResizePaneRight";
        })
        (mkZedKeymap "(Editor||Terminal||ProjectPanel||DebugPanel||Agent) && not_editing" {
          ctrl-p = "workspace::Open";
          ctrl-S = "project_panel::Toggle";
          ctrl-s = "project_panel::ToggleFocus";
          ctrl-T = "terminal_panel::Toggle";
          ctrl-t = "terminal_panel::ToggleFocus";
          ctrl-D = "debug_panel::Toggle";
          ctrl-A = "agent::ToggleFocus";
          alt-t = "task::Spawn";
          alt-T = "task::Rerun";
          "ctrl-g ctrl-g" = [
            "task::Spawn"
            {
              task_name = "jjui";
              reveal_target = "center";
            }
          ];
          "ctrl-g ctrl-n" = [
            "task::Spawn"
            {
              task_name = "nushell";
              reveal_target = "center";
            }
          ];
        })
        (mkZedKeymap "not_editing" {
          "space f" = "file_finder::Toggle";
        })
        (mkZedKeymap "AgentPanel" {
          alt-q = "workspace::CloseActiveDock";
          alt-s = "agent::OpenHistory";
          shift-tab = "agent::CycleModeSelector";
          tab = "agent::CycleModeSelector";
          alt-n = [
            "agent::NewExternalAgentThread"
            { agent.custom.name = "opencode"; }
          ];
        })
        (mkZedKeymap "VimControl" {
          ctrl-b = null;
          space = null;
        })
        (mkZedKeymap "Pane" {
          ctrl-w = null;
          alt-q = "pane::CloseActiveItem";
        })
        (mkZedKeymap "Editor && (vim_mode == helix_normal || vim_mode == helix_select)" {
          "space B" = "editor::BlameHover";
          "space b" = "tab_switcher::ToggleAll";
          D = "editor::SelectToEndOfLine";
          ctrl-j = "editor::MoveLineDown";
          ctrl-k = "editor::MoveLineUp";
          # "' t" = "";
          # "' r" = "";
          # "' k" = "";
          # "' m" = "";
          # "' c" = "";
        })
        (mkZedKeymap "Terminal" {
          alt-q = "pane::CloseActiveItem";
          alt-H = "pane::SplitLeft";
          alt-L = "pane::SplitRight";
          alt-w = "workspace::ActivateNextPane";
          alt-n = "workspace::NewTerminal";
          alt-u = "terminal::ScrollHalfPageUp";
          alt-d = "terminal::ScrollHalfPageDown";
        })
        (mkZedKeymap "ProjectPanel && not_editing" {
          "/" = null;
          alt-q = "workspace::CloseActiveDock";
          n = "project_panel::NewFile";
          r = "project_panel::Rename";
          "z a" = "project_panel::FoldDirectory";
        })
      ];

      zedTasks = [
        {
          label = "jjui";
          command = "kitty --class 'jj_float' -e 'jjui'";
          reveal_target = "center";
          use_new_terminal = true;
          allow_concurrent_runs = false;
          working_directory = "$ZED_WORKTREE_ROOT";
          hide = "on_success";
          reveal = "always";
        }
        {
          label = "nushell";
          command = "kitty --class 'jj_float' -e 'nu'";
          reveal_target = "center";
          use_new_terminal = true;
          allow_concurrent_runs = false;
          working_directory = "$ZED_WORKTREE_ROOT";
          hide = "on_success";
          reveal = "always";
        }
      ];

      zedDebug = [ ];
    in
    {
      environment.systemPackages =
        singleton
          inputs.zed.packages.${pkgs.stdenv.hostPlatform.system}.default;

      hjem.extraModules = singleton {
        packages = singleton (mkDesktopEntry {
          name = "Zed";
          exec = "/run/current-system/sw/bin/zed";
        });

        xdg.config.files = {
          "zed/settings.json".source = json.generate "zed-settings.json" zedConfig;
          "zed/keymap.json".source = json.generate "zed-keymap.json" zedKeymaps;
          "zed/tasks.json".source = json.generate "zed-tasks.json" zedTasks;
          "zed/debug.json".source = json.generate "zed-debug.json" zedDebug;
        };
      };
    };

  editorExtra =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = [
          # Rust
          # rust-analyzer is in modules/common/rust.nix
          pkgs.lldb

          # Assembler
          pkgs.asm-lsp

          # TypeScript etc.
          pkgs.deno

          # Nix
          pkgs.nixd
          pkgs.nixfmt

          # YAML
          pkgs.yaml-language-server

          # JSON
          pkgs.vscode-json-languageserver

          # TOML
          pkgs.taplo

          # Svelte
          pkgs.svelte-language-server

          # SQL
          pkgs.sqruff

          # Markdown
          pkgs.marksman

          # Just
          pkgs.just-lsp

          # Haskell
          pkgs.fourmolu
          pkgs.haskell-language-server

          # Nushell
          inputs.nu-lint.packages.${pkgs.stdenv.hostPlatform.system}.default
          # (inputs.nufmt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
          #   # Fix various random build errors.
          #   doCheck = false;
          #   patches = [ ];
          # })

          # Typos
          pkgs.typos-lsp
        ];
      };
    };
in
{
  flake-file.inputs = {
    helix = {
      url = "github:helix-editor/helix";

      inputs.nixpkgs.follows = "os";
    };

    zed = {
      url = "github:zed-industries/zed";

      inputs.nixpkgs.follows = "os";
    };

    nu-lint = {
      url = "git+https://codeberg.org/wvhulle/nu-lint";

      inputs.nixpkgs.follows = "os";
    };

    nufmt = {
      url = "github:nushell/nufmt";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.helix = helixBase;
  flake.modules.darwin.helix = helixBase;

  flake.modules.nixos.editor-extra = editorExtra;
  flake.modules.darwin.editor-extra = editorExtra;

  flake.modules.nixos.zed = zedBase;
  flake.modules.darwin.zed = zedBase;

  flake.modules.nixos.disable-nano = disableNano;
  flake.modules.darwin.disable-nano = disableNano;
}
