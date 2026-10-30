{ self, ... }:
let
  oxfmtJsTsLanguages = {
    JavaScript = "js";
    JSX = "jsx";
    TSX = "tsx";
    TypeScript = "ts";
  };
in
{
  flake.modules.common.default.imports = [
    self.modules.common.disable-nano
    self.modules.common.mitos
  ];

  flake.modules.common.disable-nano = {
    programs.nano.enable = false;
  };

  flake.modules.common.mitos =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        attrValues
        mapAttrs
        optionalAttrs
        ;
      inherit (lib.lists) elem singleton;
      inherit (config) theme;

      oxfmtConfigFile = pkgs.writers.writeJSON ".oxfmtrc.json" {
        bracketSameLine = true;
        printWidth = 100;
        proseWrap = "always";
        semi = true;
        tabWidth = 3;
        useTabs = true;
      };

      oxfmtArgs = [
        "--config"
        "${oxfmtConfigFile}"
      ];
    in
    {
      shellAliases.hx = "ms";

      environment.systemPackages =
        singleton
          inputs.mitos.packages.${pkgs.stdenv.hostPlatform.system}.mitos;

      hjemModule = { config, ... }: {
        xdg.config.files = {
          "mitos/config.toml" = {
            generator = pkgs.writers.writeTOML "mitos-config.toml";
            value = {
              theme = theme.mitos;

              editor = {
                bufferline = "multiple";
                completion-timeout = 5;
                completion-replace = true;
                completion-trigger-len = 1;
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
                statusline = {
                  diagnostics = [
                    "hint"
                    "info"
                    "warning"
                    "error"
                  ];
                };
                lsp.display-inlay-hints = true;
                inline-diagnostics = {
                  cursor-line = "hint";
                  other-lines = "disable";
                };
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
                workspace-trust.trusted = singleton "~/projects/*";
              };

              keys =
                let
                  shared = {
                    # Move lines up and down. Use `z` register to avoid clobbering system or primary clipboard.
                    "C-j" = "@X\"zd\"zp";
                    "C-k" = "@X\"zdk\"zP";

                    "q" = "record_macro";
                    "@" = "replay_macro";

                    "C-x" = "select_line_above";

                    "D" = "extend_to_line_end";

                    space."B" = ":blame";
                  };
                in
                {
                  select = shared;
                  normal = shared // {
                    "'" = {
                      label = "File Management";
                      t = {
                        label = "Touch";
                        command = "@:sh touch <C-r>%";
                      };
                      r = {
                        label = "Remove";
                        command = "@:sh rm <C-r>%";
                      };
                      k = {
                        label = "Make directory";
                        command = "@:sh mkdir <C-r>%";
                      };
                      m = {
                        label = "Move";
                        command = "@:sh mv <C-r>% <C-r>%";
                      };
                      c = {
                        label = "Copy";
                        command = "@:sh cp <C-r>% <C-r>%";
                      };
                    };
                  };

                  # TODO: Check later after version bump. It doesn't work for some reason.
                  picker = {
                    "C-d" = "preview_scroll_down";
                    "C-u" = "preview_scroll_up";
                  };
                };
            };
          };
          "mitos/languages.toml" = {
            generator = pkgs.writers.writeTOML "mitos-languages.toml";
            value = {
              language =
                let
                  languageConfig =
                    name: ext:
                    {
                      inherit name;
                      auto-format = true;
                      formatter.command = "oxfmt";
                      formatter.args = oxfmtArgs ++ [
                        "--stdin-filepath"
                        "%{buffer_name}"
                      ];
                    }
                    // optionalAttrs (elem ext (attrValues oxfmtJsTsLanguages)) {
                      language-servers = singleton "deno";
                    };

                  oxfmtLanguages =
                    {
                      css = "css";
                      javascript = "js";
                      json = "json";
                      jsonc = "jsonc";
                      jsx = "jsx";
                      markdown = "md";
                      scss = "scss";
                      tsx = "tsx";
                      typescript = "ts";
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
                      language-servers = [
                        "nil"
                      ];
                      formatter = {
                        command = "organix";
                        args = singleton "-";
                      };
                    }
                    {
                      name = "toml";
                      auto-format = true;
                      formatter.command = "taplo";
                      formatter.args =
                        let
                          configFile = (pkgs.formats.toml { }).generate "taplo.toml" {
                            formatting = {
                              align_entries = true;
                              column_width = 100;
                              compact_arrays = false;
                              reorder_inline_tables = true;
                              reorder_keys = true;
                            };

                            rule = [
                              {
                                include = [ "**/Cargo.toml" ];
                                keys = [ "package" ];
                                formatting.reorder_keys = false;
                              }
                            ];
                          };
                        in
                        [
                          "fmt"
                          "--config"
                          "${configFile}"
                          "-"
                        ];
                    }
                    {
                      name = "markdown";
                      auto-format = true;
                      language-servers = singleton "markdown-oxide";
                      spelling.languages = singleton "en_US";
                    }
                    {
                      name = "git-commit";
                      spelling.languages = singleton "en_US";
                    }
                    {
                      name = "jjdescription";
                      spelling.languages = singleton "en_US";
                    }
                    {
                      name = "just";
                      formatter.command = "just-formatter";
                    }
                    {
                      name = "nu";
                      auto-format = true;
                      formatter.command = "nufmt";
                      formatter.args = [
                        "--config"
                        "${config.directory}/.config/nufmt/config.nuon"
                        "--stdin"
                      ];
                      language-servers = [
                        "nu-lsp"
                        "nu-lint"
                      ];
                      indent = {
                        tab-width = 3;
                        unit = "   ";
                      };
                    }
                    {
                      name = "lang";
                      scope = "source.lang";
                      file-types = [ "lang" ];
                      comment-tokens = [ "#" ];
                      indent = {
                        tab-width = 3;
                        unit = "   ";
                      };
                    }
                  ];
                in
                oxfmtLanguages ++ baseLanguages;

              language-server = {
                nil = {
                  command = "nil";
                  config.nil = {
                    maxMemoryMB = 8192;
                    flake = {
                      autoArchive = true;
                      autoEvalInputs = true;
                    };
                    nixpkgsInputName = "nixpkgs";
                  };
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
                indent_char: "space"
                line_length: 100
                margin: 1
              }
            '';

          "nu-lint.toml" = {
            generator = pkgs.writers.writeTOML "nu-lint.toml";
            value = {
              max_pipeline_length = 60;
              pipeline_placement = "start";
              explicit_optional_access = true;

              rules = {
                check_typed_flag_before_use = "off";
                print_and_return_data = "off";
                max_function_body_length = "off";
                error_make_for_non_fatal = "off";
                exit_only_in_main = "off";
                dont_mix_different_effects = "off";
                redundant_ignore = "off";
                string_may_be_bare = "off";
                max_positional_params = "off";
              };
            };
          };
        };
      };
    };

  flake.modules.common.desktop = self.modules.common.editor-extra;
  flake.modules.common.editor-extra =
    {
      inputs,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        # Rust
        # rust-analyzer is in modules/common/rust.nix
        pkgs.lldb
        pkgs.leptosfmt

        # Assembler
        pkgs.asm-lsp

        # TypeScript etc.
        # deno kept for its LSP; formatting goes through oxfmt.
        pkgs.deno
        pkgs.oxfmt

        # Nix
        pkgs.nil
        inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.organix

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
        pkgs.markdown-oxide

        # Just
        pkgs.just-lsp

        # Haskell
        pkgs.fourmolu
        pkgs.stylish-haskell
        pkgs.haskell-language-server

        # Nushell
        pkgs.nu-lint
        pkgs.nufmt

        # QML
        pkgs.qt6Packages.qtdeclarative
      ];
    };
}
