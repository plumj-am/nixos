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
        virtual_text     = false;
        float.focusable  = false;
        float.source     = "always";
        float.header     = "";
        float.prefix     = "";
      };
    };
    globals.rustaceanvim = {
      tools.test_executor = "background";
      server.default_settings = mkLuaInline ''
        {
          ["rust-analyzer"] = {
            assist = {
              preferSelf = true,
            },
            -- checkOnSave and diagnostics must be disabled for bacon-ls
            checkOnSave = {
              command = "clippy",
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
              callable = {
                snippets = "add_parentheses",
              },
            },
          },
        }
      '';
      dap = { };
    };

    #==============#
    # LANG SUPPORT #
    #==============#

    languages.enableFormat     = true; # enable formatters for all enabled langs
    languages.enableTreesitter = true; # enable treesitter for all enabled langs

    languages.html = enabled;

    languages.css = enabled {
      lsp         = enabled;
      format.type = "prettierd";
    };

    languages.rust = enabled {
      dap        = enabled;
    # lsp handled by rustacean.vim
      crates     = enabled;
    };

    languages.assembly = enabled {
      lsp = enabled;
    };

    languages.astro = enabled {
      lsp         = enabled;
      format.type = "prettierd";
    };

    languages.ts = enabled {
      lsp   = enabled {
        server = "denols";
      };
      format.type = "prettierd";
    };

    languages.lua = enabled {
      lsp = enabled;
    };

    languages.nix = enabled {
      lsp    = enabled {
        server = "nixd";
      };
      format = disabled {
        # prefer to manually format for configs
        type = "alejandra";
      };
    };

    languages.nu = enabled {
      lsp = enabled;
    };

    languages.svelte = enabled {
      lsp         = enabled;
      format.type = "prettier";
    };

    languages.tailwind = enabled {
      lsp = enabled;
    };

    languages.yaml = enabled; # lsp handled in ./langs.nix

    languages.go = enabled {
      lsp         = enabled;
      dap         = enabled;
      format.type = "gofumpt";
    };

    languages.markdown = enabled {
      lsp = enabled;

      extensions.render-markdown-nvim = enabled {
        setupOpts = {
          enabled = false; # off by default

          sign.enabled = false;

          completions.blink.enabled = true;

          file_types = [ "markdown" "md" ];
          overrides.buftype.nofile = {
            render_modes       = true;
            link.enabled       = false;
            heading.enabled    = false;
            code.language_icon = false;
            code.language_name = false;
            code.language_info = false;
          };
        };
      };
    };

    #============#
    # TREESITTER #
    #============#
    treesitter = enabled {
      grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        astro      # needed manually for astro hl
        typescript # needed manually for astro hl
        vim json vimdoc
        http nasm asm
      ];
      fold        = true;
      indent      = enabled;
      highlight   = enabled;
      textobjects = enabled;
      autotagHtml = true;
      context     = enabled {
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
      #   root_markers = [ "Cargo.toml" "Cargo.lock" ".bacon-locations" ];
      #   filetypes    = [ "rust" ];
      #   cmd          = [ "bacon-ls" ];
      #   settings.init_options = {
      #     locationsFile        = ".bacon-locations";
      #     runBaconInBackground = true;
      #     updateOnSave         = true;

      #     updateOnSaveWaitMillis            = 100;
      #     synchronizeAllOpenFilesWaitMillis = 1000;
      #   };
      # };

      json_ls = {
        filetypes     = [ "json" "jsonc" ];
        settings.json = {
          schema   = mkLuaInline ''require("schemastore").json.schemas()'';
          validate = enabled;
        };

      };

      "yamlls" = {
        filetypes     = [ "yaml" ];
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
