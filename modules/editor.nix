let
  commonModule =
    {
      inputs,
      lib,
      pkgs,
      theme,
      ...
    }:
    let
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

      package = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.helix; # `.helix` follows the master branch.
    in
    {
      rum.programs.helix = {
        enable = true;
        inherit package;

        settings.theme = if theme.color_scheme == "pywal" then "base16_custom" else theme.helix;

        # Pywal output doesn't have gradients like base16 needs.
        # So it's necessary to override a few colours.
        # Also added overrides for diagnostic colours which don't work well from Pywal.
        themes.base16_custom = {
          inherits = "base16_default";
        }
        # Comments.
        // mkFgStyle [ "comment" ] (if theme.is_dark then "#909090" else "#C0C0C0")
        # Selections.
        // mkBgStyle [ "ui.selection" "ui.selection.primary" ] (
          if theme.is_dark then "#707070" else "#E0E0E0"
        )
        # Cursorline and popups.
        // mkBgStyle [ "ui.cursorline.primary" "ui.cursorline.secondary" "ui.popup" "ui.popup.info" ] (
          if theme.is_dark then "#404040" else "#F0F0F0"
        )
        # Info.
        //
          mkFgStyle
            [ "hint" "info" "diagnostic" "diagnostic.hint" "diagnostic.info" "diagnostic.unnecessary" ]
            (
              if theme.is_dark then "#2B83A6" else "#3A8C9A" # Muted teal.
            )
        # Warnings.
        // mkFgStyle [ "warning" "diagnostic.warning" "diagnostic.deprecated" ] (
          if theme.is_dark then "#B58900" else "#9D8740" # Muted yellow.
        )
        # Errors.
        // mkFgStyle [ "error" "diagnostic.error" ] (
          if theme.is_dark then "#9D0006" else "#8F3F71" # Muted red/brown.
        );

        settings.editor = {
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
          # Nightly options:
          word-completion.trigger-length = 3;
          # rainbow-brackets               = true;
        };
        settings.editor.cursor-shape = {
          normal = "block";
          select = "underline";
          insert = "bar";
        };
        settings.editor.indent-guides = {
          character = "▏";
          render = true;
        };
        settings.editor.whitespace = {
          characters.tab = "→";
          render.tab = "all";
        };

        settings.keys = {
          normal."C-y" =
            ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- ${yaziPickerScript} open ...%{buffer_name}";
        }
        // genAttrs [ "normal" "select" ] (const {
          D = "extend_to_line_end";
        });

        languages.language =
          let
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
              |> mapAttrs (
                name: extension:
                {
                  inherit name;
                  auto-format = true;
                  formatter.command = "deno";
                  formatter.args = [
                    "fmt"
                    "--use-tabs"
                    "--no-semicolons"
                    "--indent-width"
                    "4"
                    "--unstable-component"
                    "--ext"
                    extension
                    "-"
                  ];
                }
                //
                  optionalAttrs
                    (elem name [
                      "javascript"
                      "jsx"
                      "typescript"
                      "tsx"
                    ])
                    {
                      language-servers = [
                        "deno"
                        "typos"
                      ];
                    }
              )
              |> attrValues;
          in
          denoFmtLanguages
          ++ [
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
              auto-format = false;
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

      };
      rum.programs.nushell.aliases = {
        h = "hx";
        e = "hx"; # editor
      };
    };

  editorExtra =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      rum.programs.helix.languages.language-server = {

        nixd.args = singleton "--inlay-hints";

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

      packages = [
        # Yazi file manager
        pkgs.yazi

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
        pkgs.mdformat

        # Just
        pkgs.just-lsp
        pkgs.just-formatter

        # Haskell
        pkgs.fourmolu
        pkgs.haskell-language-server

        # Typos
        pkgs.typos-lsp
      ];
    };
in
{
  config.flake.modules.nixos.disable-nano = {
    programs.nano.enable = false;
  };
  config.flake.modules.hjem.editor = commonModule;
  config.flake.modules.hjem.editor-extra = editorExtra;
}
