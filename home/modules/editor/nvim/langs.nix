{ lib, pkgs, ... }:
let
  inherit (lib) enabled disabled mkLuaInline;
in
{
  home.packages = [
    pkgs.vscode-json-languageserver
    pkgs.yaml-language-server
  ];
  programs.nvf.settings.vim = {
    diagnostics = enabled {
      config = {
        update_in_insert = false;
        virtual_text = false;
        float = {
          focusable = false;
          source = "always";
          header = "";
          prefix = "";
        };

      };
    };
    globals = {
      rustaceanvim = {
        tools.test_executor = "background";
        server.default_settings = mkLuaInline ''
          {
            ["rust-analyzer"] = {
              assist = {
                preferSelf = true,
              },
              lens = {
                references = {
                  adt = {
                    enable = true,
                  },
                  enumVariant = {
                    enable = true,
                  },
                  method = {
                    enable = true,
                  },
                  trait = {
                    enable = true,
                    all = true,
                  },
                },
              },
              inlayHints = {
                bindingModeHints = {
                  enable = true,
                },
                closureCaptureHints = {
                  enable = true,
                },
                closureReturnTypeHints = {
                  enable = true,
                },
                discriminantHints = {
                  enable = true,
                },
                expressionAdjustmentHints = {
                  enable = true,
                },
                genericParameterHints = {
                  lifetime = {
                    enable = true,
                  },
                  type = {
                    enable = true,
                  },
                },
                implicitDrops = {
                  enable = true,
                },
                implicitSizedBoundHints = {
                  enable = true,
                },
                lifetimeElisionHints = {
                  useParameterNames = true,
                  enable = true,
                },
                rangeExclusiveHints = {
                  enable = true,
                },
              },
              -- checkOnSave and diagnostics must be disabled for bacon-ls
              checkOnSave = {
                command = "clippy",
                enable = true,
              },
              diagnostics = {
                enable = true,
                experimental = {
                  enable = true,
                },
                styleLints = {
                  enable = true,
                },
              },
              hover = {
                actions = {
                  references = {
                    enable = true,
                  },
                },
              },
              interpret = {
                tests = true,
              },
              cargo = {
                features = "all",
              },
              completion = {
                hideDeprecated = true,
                fullFunctionSignatures = {
                  enable = true,
                },
              },
            },
          }
        '';
        dap = { };
      };
    };

    #==============#
    # LANG SUPPORT #
    #==============#
    languages = {
      html = enabled {
        treesitter = enabled;
      };

      css = enabled {
        treesitter = enabled;
        lsp = enabled;
        format = enabled {
          type = "prettierd";
        };
      };

      rust = enabled {
        treesitter = enabled;
        dap = enabled;
        # lsp handled in ./langs.nix
        crates = enabled;
        format = enabled;
      };

      assembly = enabled {
        treesitter = enabled;
        lsp = enabled;
      };

      astro = enabled {
        treesitter = enabled;
        lsp = enabled;
        format = enabled {
          type = "prettierd";
        };
      };

      ts = enabled {
        treesitter = enabled;
        lsp = enabled {
          server = "denols";
        };
        format = enabled {
          type = "prettierd";
        };
      };

      lua = enabled {
        treesitter = enabled;
        lsp = enabled;
        format = enabled;
      };

      nix = enabled {
        treesitter = enabled;
        lsp = enabled {
          server = "nixd";
        };
        format = enabled {
          type = "nixfmt";
        };
      };

      nu = enabled {
        treesitter = enabled;
        lsp = enabled;
      };

      svelte = enabled {
        treesitter = enabled;
        lsp = enabled;
        format = enabled {
          type = "prettier";
        };
      };

      tailwind = enabled {
        lsp = enabled;
      };

      yaml = enabled {
        treesitter = enabled;
        # lsp handled in ./langs.nix
      };

      go = enabled {
        treesitter = enabled;
        lsp = enabled;
        dap = enabled;
        format = enabled {
          type = "gofumpt";
        };
      };

      markdown = enabled {
        treesitter = enabled;
        lsp = enabled;
        extensions.render-markdown-nvim = enabled {
          setupOpts = {
            sign.enabled = false;
            completions.blink.enabled = true;
            file_types = [
              "markdown"
              "md"
            ];
            overrides.buftype.nofile = {
              render_modes = true;
              link.enabled = false;
              heading.enabled = false;
              code = {
                language_icon = false;
                language_name = false;
                language_info = false;
              };
            };
          };
        };
      };
    };

    #============#
    # TREESITTER #
    #============#
    treesitter = enabled {
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        astro # needed manually for astro hl
        typescript # needed manually for astro hl
        vim
        json
        vimdoc
        http
        nasm
        asm
      ];
      fold = true;
      indent = enabled;
      highlight = enabled;
      textobjects = enabled;
      autotagHtml = true;
      context = enabled {
        setupOpts = {
          max_lines = 3;
          separator = "▁";
        };
      };
    };

    #============#
    # OTHER LSPs #
    #============#
    lsp.servers = {
      "*" = {
        root_markers = [ ".git" ];
        capabilities = mkLuaInline ''
          					vim.tbl_deep_extend(
          						"force",
          						{},
          						vim.lsp.protocol.make_client_capabilities(),
          						require("blink.cmp").get_lsp_capabilities()
          					)
          				'';
      };
      # too inconsistent right now
      # bacon-ls = {
      #   root_markers = [
      #     "Cargo.toml"
      #     "Cargo.lock"
      #     ".bacon-locations"
      #   ];
      #   filetypes = [ "rust" ];
      #   cmd = [ "bacon-ls" ];
      #   settings = {
      #     init_options = {
      #       locationsFile = ".bacon-locations";
      #       updateOnSave = true;
      #       updateOnSaveWaitMillis = 100;
      #       runBaconInBackground = true;
      #       synchronizeAllOpenFilesWaitMillis = 1000;
      #     };
      #   };
      # };

      json_ls = {
        filetypes = [
          "json"
          "jsonc"
        ];
        settings.json = {
          schema = mkLuaInline ''require("schemastore").json.schemas()'';
          validate = enabled;
        };

      };

      "yamlls" = {
        filetypes = [ "yaml" ];
        settings.yaml = {
          # You must disable built-in schemaStore support if you want to use
          # this plugin and its advanced options like `ignore`.
          schemaStore = disabled {
            # Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = "";
          };
          schemas = mkLuaInline ''require("schemastore").yaml.schemas()'';
        };
      };
    };
  };
}
