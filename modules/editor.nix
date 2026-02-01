{
  flake-file.inputs = {
    helix = {
      url = "github:helix-editor/helix";

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

  flake.modules.nixos.disable-nano = {
    programs.nano.enable = false;
  };

  flake.modules.hjem.editor =
    {
      inputs,
      lib,
      pkgs,
      theme,
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

        keys = genAttrs [ "normal" "select" ] (const {
          "A-h" = "jump_view_left";
          "A-j" = "jump_view_down";
          "A-k" = "jump_view_up";
          "A-l" = "jump_view_right";

          "ret" = "goto_word";

          "q" = "record_macro";
          "@" = "replay_macro";

          "X" = "select_line_above";

          "C-y" =
            ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- ${yaziPickerScript} open ...%{buffer_name}";

          "C-a" = "@*%s<ret>";

          "D" = "extend_to_line_end";
        });
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
                formatter.command = "nufmt";
                formatter.args = [
                  "--config"
                  "/home/jam/.config/nufmt/config.nuon"
                  "--stdin"
                ];
                language-servers = [
                  "nu"
                  "nu-lint"
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
                yuzu.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.yuzu.options'';
                plum.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.plum.options'';
                kiwi.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.kiwi.options'';
                # date.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.date.options'';
                # pear.expr = ''(builtins.getFlake "/home/jam/nixos").nixosConfigurations.pear.options'';
                lime.expr = ''(builtins.getFlake "/home/jam/nixos").darwinConfigurations.lime.options'';
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

      toml = pkgs.formats.toml { };
    in
    {
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

  flake.modules.hjem.editor-extra =
    {
      inputs,
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isDesktop {
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

        # Markdown
        pkgs.marksman
        # pkgs.mdformat  # Temporarily disabled due to markdown-it-py 4.0.0 incompatibility

        # Just
        pkgs.just-lsp
        pkgs.just-formatter

        # Haskell
        pkgs.fourmolu
        pkgs.haskell-language-server

        # Nushell
        inputs.nu-lint.packages.${pkgs.stdenv.hostPlatform.system}.default
        (inputs.nufmt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
          doCheck = false;
        })

        # Typos
        pkgs.typos-lsp
      ];

    };
}
