{ lib, pkgs, ... }:
let
  mkLuaInline = lib.generators.mkLuaInline;
in
{
  home.packages = [
    pkgs.lua-language-server
    pkgs.typescript-language-server
    pkgs.svelte-language-server
    pkgs.tailwindcss-language-server
    pkgs.astro-language-server
    pkgs.nixd
    pkgs.gopls
    pkgs.vscode-json-languageserver
    pkgs.yaml-language-server
  ];
  programs.nvf.settings.vim = {
    diagnostics = {
      enable = true;
      config = {
        update_in_insert = false;
        virtual_text = false;
        float = {
          focusable = false;
          border = "rounded";
          source = "always";
          header = "";
          prefix = "";
        };

      };
    };
    globals = {
      rustaceanvim = {
        tools = {
          test_executor = "background";
        };
        server = {
          default_settings = mkLuaInline ''
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
                  enable = false,
                },
                diagnostics = {
                  enable = false,
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
        };
        dap = { };
      };
    };

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
      "astro" = {
        cmd = [
          "astro-ls"
          "--stdio"
        ];
        filetypes = [ "astro" ];
        root_markers = [
          "package.json"
          "bun.lock"
          "tsconfig.json"
        ];
        init_options = {
          typescript = {
            # should make this dynamic but now only care about 1 project
            tsdk = ''vim.fn.getcwd() .. "/node_modules/typescript/lib")'';
          };
        };
      };
      bacon-ls = {
        root_markers = [
          "Cargo.toml"
          "Cargo.lock"
          ".bacon-locations"
        ];
        filetypes = [ "rust" ];
        cmd = [ "bacon-ls" ];
        settings = {
          init_options = {
            locationsFile = ".bacon-locations";
            updateOnSave = true;
            updateOnSaveWaitMillis = 100;
            runBaconInBackground = true;
            synchronizeAllOpenFilesWaitMillis = 1000;
          };
        };
      };

      gopls = {
        root_markers = [
          "go.mod"
          "go.sum"
        ];
        filetypes = [ "go" ];
        cmd = [ "gopls" ];
        settings = {
          experimentalPostfixCompletions = true;
          gofumpt = true;
          staticcheck = true;
          completeUnimported = true;
          usePlaceholders = true;
          semanticTokens = true;
          codelenses = {
            run_govulncheck = true;
          };
          vulncheck = "Imports";
        };
      };

      json_ls = {
        filetypes = [
          "json"
          "jsonc"
        ];
        settings = {
          json = {
            schema = mkLuaInline ''require("schemastore").json.schemas()'';
            validate = {
              enable = true;
            };
          };
        };

      };
      lua_ls = {
        filetypes = [ "lua" ];
        cmd = [ "lua-language-server" ];
        settings = {
          Lua = {
            diagnostics = {
              globals = [
                "vim"
                "wezterm"
              ];
            };
            workspaces = {
              checkThirdParty = true;
              library = mkLuaInline ''vim.api.nvim_get_runtime_file("", true)'';
            };
          };
        };
      };

      "nixd" = {
        root_markers = [
          "flake.nix"
          ".git"
        ];
        filetypes = [ "nix" ];
        cmd = [ "nixd" ];

      };
      nushell = {
        filetypes = [ "nu" ];
        cmd = [
          "nu"
          "--lsp"
        ];
      };

      # now handled by rustaceanvim
      # "rust_analyzer" = {
      #   root_markers = [
      #     "Cargo.toml"
      #     "Cargo.lock"
      #   ];
      #   filetypes = [ "rust" ];
      #   cmd = [ "rust-analyzer" ];
      # settings = {};
      # };

      "svelteserver" = {
        root_markers = [
          "package.json"
          "bun.lock"
        ];
        filetypes = [ "svelte" ];
        cmd = [
          "svelteserver"
          "--stdio"
        ];
      };

      "tailwindcss" = {
        root_markers = [
          "package.json"
          "bun.lock"
        ];
        filetypes = [
          "astro"
          "svelte"
          "tsx"
          "jsx"
          "html"
          "vue"
        ];
        cmd = [
          "tailwindcss-language-server"
          "--stdio"
        ];
      };

      "ts_ls" = {
        root_markers = [
          "package.json"
          "bun.lock"
          "package-lock.json"
        ];
        filetypes = [
          "typescript"
          "javascript"
          "javascriptreact"
          "typescriptreact"
          "vue"
        ];
        cmd = [
          "bunx"
          "--bun"
          "typescript-language-server"
          "--stdio"
        ];
        # init_options = {
        # plugins = mkLuaInline ''
        #   {
        #     {
        #       name = "@vue/typescript-plugin",
        #       location = vim.fn.exepath("vue-language-server"),
        #       languages = { "vue" },
        #     }
        #   }
        # '';
        # };
      };

      "yamlls" = {
        filetypes = [ "yaml" ];
        settings = {
          yaml = {
            schemaStore = {
              # You must disable built-in schemaStore support if you want to use
              # this plugin and its advanced options like `ignore`.
              enable = false;
              # Avoid TypeError: Cannot read properties of undefined (reading 'length')
              url = "";
            };
            schemas = mkLuaInline ''require("schemastore").yaml.schemas()'';
          };
        };
      };

      "asm_lsp" = {
        filetypes = [
          "asm"
          "fasm"
          "nasm"
        ];
        cmd = [ "asm-lsp" ];
        root_markers = [ ".git" ];
      };
    };

    languages = {
      enableTreesitter = true;
    };
  };
}
