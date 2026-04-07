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
      inherit (lib.attrsets)
        mapAttrs'
        nameValuePair
        optionalAttrs
        attrValues
        mapAttrs
        ;
      inherit (lib.lists) singleton;
      inherit (lib) elem;
      inherit (config) theme;

      mkThemes =
        themes:
        mapAttrs' (
          name: value:
          nameValuePair "helix/themes/${name}.toml" {
            generator = pkgs.writers.writeTOML "helix-theme-${name}";
            inherit value;
          }
        ) themes;

      themes.base16_custom.inherits = "base16_default";
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.helix;

        xdg.config.files = {
          "helix/config.toml" = {
            generator = pkgs.writers.writeTOML "helix-config.toml";
            value = {
              theme = if theme.colorScheme == "matugen" then "base16_custom" else theme.helix;

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
                  "C-j" = "@X*dp";
                  "C-k" = "@X*dkP";

                  "ret" = "goto_word";

                  "q" = "record_macro";
                  "@" = "replay_macro";

                  "C-X" = "select_line_above";

                  "C-a" = "@*%s<ret>";

                  "D" = "extend_to_line_end";

                  "space"."B" =
                    '':sh echo $"# git blame:(char nl)  (git blame -L %{cursor_line},+1 %{buffer_name} | cut -c1-60)"'';
                };

                normal = {
                  # Move lines up and down. Use `z` register to avoid clobbering system or primary clipboard.
                  "C-j" = "@X\"zd\"zp";
                  "C-k" = "@X\"zdk\"zP";

                  "ret" = "goto_word";

                  "q" = "record_macro";
                  "@" = "replay_macro";

                  "C-X" = "select_line_above";

                  "C-a" = "@*%s<ret>";

                  "D" = "extend_to_line_end";

                  "space"."B" =
                    '':sh echo $"# git blame:(char nl)  (git blame -L %{cursor_line},+1 %{buffer_name} | cut -c1-60)"'';

                  "'" = {
                    # Hack to have a custom popup helper with a title.
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
          };
          "helix/languages.toml" = {
            generator = pkgs.writers.writeTOML "helix-languages.toml";
            value = {
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
                    procMacro.enable = true;
                    check.command = "clippy";
                    inlayHints.enable = true;
                    diagnostics.experimental.enable = true;
                    completion.callable.snippets = "add_parentheses";

                    # <https://zed.dev/docs/languages/rust>
                    completion.snippets.custom = {
                      "Arc::new" = {
                        postfix = "arc";
                        body = [ "Arc::new(\${receiver})" ];
                        requires = "std::sync::Arc";
                        scope = "expr";
                      };
                      "Some" = {
                        postfix = "some";
                        body = [ "Some(\${receiver})" ];
                        scope = "expr";
                      };
                      "Ok" = {
                        postfix = "ok";
                        body = [ "Ok(\${receiver})" ];
                        scope = "expr";
                      };
                      "Rc::new" = {
                        postfix = "rc";
                        body = [ "Rc::new(\${receiver})" ];
                        requires = "std::rc::Rc";
                        scope = "expr";
                      };
                      "Box::pin" = {
                        postfix = "boxpin";
                        body = [ "Box::pin(\${receiver})" ];
                        requires = "std::boxed::Box";
                        scope = "expr";
                      };
                      "vec!" = {
                        postfix = "vec";
                        body = [ "vec![\${receiver}]" ];
                        description = "vec![]";
                        scope = "expr";
                      };
                    };
                  };
                };
              };
            };
          };

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
          pkgs.stylish-haskell
          pkgs.haskell-language-server

          # Nushell
          inputs.nu-lint.packages.${pkgs.stdenv.hostPlatform.system}.default
          # (inputs.nufmt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
          #   # Fix various random build errors.
          #   doCheck = false;
          #   patches = [ ];
          # })

          # QML
          pkgs.qt6Packages.qtdeclarative

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

  flake.modules.nixos.disable-nano = disableNano;
  flake.modules.darwin.disable-nano = disableNano;
}
