let
  withTypos = lsps: lsps ++ [ "typos" ];

  denoJsTsLanguages = {
    JavaScript = "js";
    JSX = "jsx";
    TSX = "tsx";
    TypeScript = "ts";
  };

  denoFmtArgs = [
    "fmt"
    "--use-tabs"
    "--no-semicolons"
    "--indent-width"
    "4"
    "--unstable-component"
    "--ext"
  ];

  disableNano = {
    programs.nano.enable = false;
  };

  helixBase =
    {
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
      inherit (lib) elem;
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
        genAttrs colors
        <| const {
          fg = color;
        };

      mkBgStyle =
        colors: color:
        genAttrs colors
        <| const {
          bg = color;
        };

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
            languageConfig =
              name: ext:
              {
                inherit name;
                auto-format = true;
                formatter.command = "deno";
                formatter.args = denoFmtArgs ++ [
                  "--ext"
                  ext
                  "-"
                ];
              }
              // optionalAttrs (elem ext (attrValues denoJsTsLanguages)) {
                language-servers = withTypos [ "deno" ];
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
                language-servers = withTypos [
                  {
                    name = "rust-analyzer";
                    except-features = singleton "inlay-hints";
                  }
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
                language-servers = withTypos [ "nixd" ];
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
                language-servers = withTypos [ "typos" ];
              }
              {
                name = "markdown";
                auto-format = true;
                language-servers = withTypos [ "marksman" ];
              }
              {
                name = "just";
                auto-format = true;
                formatter.command = "just-formatter";
                language-servers = withTypos [ "just-lsp" ];
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
                language-servers = withTypos [
                  "nu-lsp"
                  # "nu-lint" # Waiting for <https://codeberg.org/wvhulle/nu-lint/pulls/96>
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
              nixpkgs.expr = ''import (lib.getFlake "/home/jam/nixos").inputs.os { }'';
              options = {
                current-host.expr = ''(lib.getFlake "/home/jam/nixos").nixosConfigurations.${config.networking.hostName}.options'';
                flake-parts.expr = ''(lib.getFlake "/home/jam/nixos").debug.options'';
                flake-parts2.expr = ''(lib.getFlake "/home/jam/nixos").currentSystem.options'';
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
        packages = singleton pkgs.helix;

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
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (config.myLib) mkDesktopEntry;
      inherit (config.age) secrets;

      json = pkgs.formats.json { };

      zedPackage = pkgs.symlinkJoin {
        name = "zed-wrapped";
        paths = singleton pkgs.zed-editor-fhs;
        buildInputs = singleton pkgs.makeWrapper;
        postBuild = # sh
          ''
            wrapProgram $out/bin/zeditor \
              --run 'export ZAI_API_KEY="$(cat ${secrets.zaiKey.path})"'
          '';
      };
    in
    {
      nix.settings = {
        extra-substituters = singleton "https://zed.cachix.org";
        extra-trusted-public-keys = singleton "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU=";
      };

      hjem.extraModules = singleton {
        packages = singleton zedPackage;

        xdg.config.files = {
          "zed/settings.json".source =
            json.generate "zed-settings.json" <| import ./_zed/settings.nix { inherit lib config; };

          "zed/keymap.json".source = json.generate "zed-keymap.json" <| import ./_zed/keymap.nix;

          "zed/tasks.json".source =
            json.generate "zed-tasks.json" <| import ./_zed/tasks.nix { inherit pkgs lib; };

          "zed/debug.json".source = json.generate "zed-debug.json" <| import ./_zed/debug.nix;
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
          pkgs.nil
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

          # QML
          pkgs.qt6Packages.qtlanguageserver

          # Typos
          pkgs.typos-lsp
        ];
      };
    };
in
{
  flake.modules.nixos.helix = helixBase;
  flake.modules.darwin.helix = helixBase;

  flake.modules.nixos.editor-extra = editorExtra;
  flake.modules.darwin.editor-extra = editorExtra;

  flake.modules.nixos.zed = zedBase;
  flake.modules.darwin.zed = zedBase;

  flake.modules.nixos.disable-nano = disableNano;
  flake.modules.darwin.disable-nano = disableNano;
}
