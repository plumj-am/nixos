{ pkgs, lib, config, ... }: let
  inherit (lib) enabled const genAttrs mkIf;
in {
  environment.shellAliases = {
    nvim = "echo 'no more neovim, use hx'";
    nv   = "echo 'no more neovim, use hx'";
    vim  = "echo 'no more vim, use hx'";
    v    = "echo 'no more vim, use hx'";
    h    = "hx";
    e    = "hx"; # editor
  };

  environment.systemPackages = mkIf config.isDesktop [
    # rust-analyzer is in modules/common/rust.nix

    # TypeScript etc.
    pkgs.deno

    # Nix
    pkgs.nixd

    # YAML
    pkgs.yaml-language-server

    # Svelte
    pkgs.svelte-language-server

    # Markdown
    pkgs.mdformat
  ];

  home-manager.sharedModules = [{
    programs.helix = enabled {
    settings.theme = config.theme.helix;
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
    };
    settings.editor.cursor-shape = {
      insert = "block";
      normal = "block";
      select = "underline";
    };
    settings.editor.statusline.mode = {
      insert = "INSERT";
      normal = "NORMAL";
      select = "SELECT";
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
      "C-y" = ":sh zellij run -n Yazi -c -f -x 10%% -y 10%% --width 80%% --height 80%% -- bash ~/.config/helix/yazi-picker.sh open %{buffer_name}";
    };

    languages.language = [
      {
        name              = "rust";
        auto-format       = true;
      }
      {
        name              = "typescript";
        auto-format       = true;
        formatter.command = "deno";
        formatter.args    = [ "fmt" "--use-tabs" "--no-semicolons" "--indent-width" "4" "--unstable-component" "--ext" "ts" "-"];
      }
      {
        name              = "svelte";
        auto-format       = true;
        formatter.command = "deno";
        formatter.args    = [ "fmt" "--use-tabs" "--no-semicolons" "--indent-width" "4" "--unstable-component" "--ext" "svelte" "-"];
      }
      {
        name              = "nix";
        auto-format       = false;
        formatter.command = "alejandra";
      }
      {
        name              = "toml";
        auto-format       = true;
      }
      {
        name              = "markdown";
        auto-format       = false;
        formatter.command = "mdformat";
        formatter.args    = [ "--wrap=80" "--number" "-" ];
      }
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

      svelte-language-server = {
        command = "svelteserver";
        args    = [ "stdio" ];
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
  home.file.".config/helix/yazi-picker.sh" = {
    text = ''
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
  };
  }];
}
