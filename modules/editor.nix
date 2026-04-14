let
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
in
{
  flake.modules.common.disable-nano = {
    programs.nano.enable = false;
  };

  flake.modules.common.helix =
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
      hjem.extraModule = {
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
                      language-servers = singleton "deno";
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
                      language-servers = singleton {
                        name = "rust-analyzer";
                        except-features = singleton "inlay-hints";
                      };
                      indent = {
                        tab-width = 3;
                        unit = "   ";
                      };
                    }
                    {
                      name = "haskell";
                      auto-format = true;
                      indent = {
                        tab-width = 3;
                        unit = "   ";
                      };
                      formatter = {
                        command = "stylish-haskell";
                        args = singleton "--in-place";
                      };
                    }
                    {
                      name = "nix";
                      auto-format = true;
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
                    }
                    {
                      name = "markdown";
                      auto-format = true;
                      language-servers = [ "marksman" ];
                    }
                    {
                      name = "just";
                      formatter.command = "just-formatter";
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
                      ];
                      indent = {
                        tab-width = 3;
                        unit = "   ";
                      };
                    }
                  ];
                in
                denoFmtLanguages ++ baseLanguages;

              language-server = {
                nil = {
                  command = "nil";
                  config.nil = {
                    maxMemoryMB = 8192;
                    flake = {
                      autoArchive = true;
                      autoEvalInputs = true;
                    };
                    nixpkgsInputName = "os";
                  };
                };
                nixd = {
                  command = "nixd";
                  args = singleton "--inlay-hints";
                };

                deno = {
                  command = "deno";
                  args = singleton "lsp";

                  config.javascript = {
                    enable = true;
                    lint = true;
                    unstable = true;

                    suggest.imports.hosts."https://deno.land" = true;

                    inlayHints = {
                      enumMemberValues.enabled = true;
                      functionLikeReturnTypes.enabled = true;
                      parameterNames.enabled = "all";
                      parameterTypes.enabled = true;
                      propertyDeclarationTypes.enabled = true;
                      variableTypes.enabled = true;
                    };
                  };
                };

                rust-analyzer = {
                  config = {
                    cargo.features = "all";
                    procMacro.enable = true;
                    check.command = "clippy";
                    diagnostics = {
                      experimental.enable = true;
                      styleLints.enable = true;
                    };
                    completion = {
                      callable.snippets = "add_parentheses";

                      # <https://zed.dev/docs/languages/rust>
                      snippets.custom = {
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
                haskell-language-server = {
                  config.haskell = {
                    plugin = {
                      hlint.globalOn = true;
                    };
                    cabalFormattingProvider = "cabal-fmt";
                    formattingProvider = "fourmolu";
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

  flake.modules.common.editor-extra =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      hjem.extraModule = {
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

          # QML
          pkgs.qt6Packages.qtdeclarative
        ];
      };
    };
}
