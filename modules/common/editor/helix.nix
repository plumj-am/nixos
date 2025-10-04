{ pkgs, lib, config, helix, ... }: let
  inherit (lib) enabled const genAttrs mkIf elem mapAttrs optionalAttrs attrValues;

  yaziPickerScript = pkgs.writeShellScript "yazi-picker.sh" ''
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
in {

  home-manager.sharedModules = [{
    programs.helix = enabled {
      package = helix.packages.${pkgs.system}.helix; # [`.helix`] follows the master branch.
      settings.theme.fallback = config.theme.helix;
      settings.theme.dark     = config.theme.themes.helix.dark;
      settings.theme.light    = config.theme.themes.helix.light;
      settings.editor = {
        completion-timeout             = 5;
        color-modes                    = true;
        cursorline                     = true;
        file-picker.hidden             = false;
        idle-timeout                   = 0;
        shell                          = [ "nu" "--commands" ];
        trim-trailing-whitespace       = true;
        true-color                     = true;
        lsp.display-inlay-hints        = true;
        inline-diagnostics.cursor-line = "hint";
        # Nightly options:
        word-completion.trigger-length = 3;
        # rainbow-brackets               = true;
      };
      settings.editor.cursor-shape = {
        select = "underline";
      };
      settings.editor.indent-guides = {
        character = "▏";
        render = true;
      };
      settings.editor.whitespace = {
        characters.tab = "→";
        render.tab     = "all";
      };

      settings.keys = genAttrs [ "normal" "select" ] <| const {
        D = "extend_to_line_end";

        "C-y" = ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- ${yaziPickerScript} open %{buffer_name}";
      };

      languages.language = let
        denoFmtLanguages = {
          astro = "astro";  css        = "css";
          html  = "html";   javascript = "js";
          json  = "json";   jsonc      = "jsonc";
          jsx   = "jsx";    markdown   = "md";
          scss  = "scss";   svelte     = "svelte";
          tsx   = "tsx";    typescript = "ts";
          vue   = "vue";    yaml       = "yaml";
        }
        |> mapAttrs (name: extension: {
          inherit name;
          auto-format       = true;
          formatter.command = "deno";
          formatter.args    = [ "fmt" "--use-tabs" "--no-semicolons" "--indent-width" "4" "--unstable-component" "--ext" extension "-" ];
        } // optionalAttrs (elem name [ "javascript" "jsx" "typescript" "tsx" ]) {
          language-servers = [ "deno" ];
        })
        |> attrValues;
      in denoFmtLanguages ++ [
        {
          name              = "nix";
          auto-format       = false;
          formatter.command = "alejandra";
        }
        {
          name              = "toml";
          auto-format       = true;
          formatter.command = "taplo";
          formatter.args    = [ "fmt" "--option" "align_entries=true" "--option" "column_width=100" "--option" "compact_arrays=false" "--option" "reorder_inline_tables=true" "--option" "reorder_keys=true" "-" ];
        }
        {
          name              = "markdown";
          auto-format       = false;
          formatter.command = "mdformat";
          formatter.args    = [ "--wrap=80" "--number" "-" ];
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

      languages.language-server = mkIf config.isDesktop {
        deno = {
          command = "deno";
          args    = [ "lsp" ];

          config.javascript = enabled {
            lint     = true;
            unstable = true;

            suggest.imports.hosts."https://deno.land" = true;

            inlayHints.enumMemberValues.enabled         = true;
            inlayHints.functionLikeReturnTypes.enabled  = true;
            inlayHints.parameterNames.enabled           = "all";
            inlayHints.parameterTypes.enabled           = true;
            inlayHints.propertyDeclarationTypes.enabled = true;
            inlayHints.variableTypes.enabled            = true;
          };
        };

        rust-analyzer = {
          config = {
            cargo.features               = "all";
            check.command                = "clippy";
            completion.callable.snippets = "add_parentheses";
          };
        };
      };
    };
  }];

  environment.shellAliases = {
    nvim = "echo 'no more neovim, use hx'";
    nv   = "echo 'no more neovim, use hx'";
    vim  = "echo 'no more vim, use hx'";
    v    = "echo 'no more vim, use hx'";
    h    = "hx";
    e    = "hx"; # editor
  };

  environment.systemPackages = mkIf config.isDesktop [
    # Rust
    # rust-analyzer is in modules/common/rust.nix
    pkgs.lldb

    # Assembler
    pkgs.asm-lsp

    # TypeScript etc.
    pkgs.deno

    # Nix
    pkgs.nixd
    pkgs.alejandra

    # YAML
    pkgs.yaml-language-server

    # JSON
    pkgs.vscode-json-languageserver

    # TOML
    pkgs.taplo

    # Svelte
    pkgs.svelte-language-server

    # Markdown
    pkgs.mdformat

    # Just
    pkgs.just-lsp
    pkgs.just-formatter
  ];
}
