{ pkgs, ... }:
{
  home.packages = [
    pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter
    pkgs.vscode-js-debug
  ];

  programs.nvf.settings.vim.lazy.plugins = {
    "nvim-dap" = {
      package = pkgs.vimPlugins.nvim-dap;
      lazy = true;
      after = ''
        	local dap = require('dap')

        	dap.adapters.codelldb = {
        		type = 'executable',
        		command = 'codelldb',
        	}

        	dap.adapters["pwa-node"] = {
        			type = "server",
        			host = "localhost", 
        			port = "''${port}",
        			executable = {
        				command = "js-debug",
        				args = {
        					"''${port}"
        				}
        			},
        			processId = require("dap.utils").pick_process,
        		}

        		dap.configurations.rust = {
        			{
        				name = 'Launch file',
        				type = 'codelldb',
        				request = 'launch',
        				program = function()
        					return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        				end,
        				cwd = vim.fn.getcwd(),
        				stopOnEntry = false,
        			}
        		}

        		dap.configurations.javascript = {
        			{
        			type = "pwa-node",
        			request = "launch",
        			name = "Launch File",
        			program = "''${file}",
        			cwd = "''${workspaceFolder}",
        			}
        		}

        		dap.configurations.typescript = {
        			{
        				type = "pwa-node",
        				request = "launch",
        				name = "Launch File",
        				program = "''${workspaceFolder}/../node_modules/astro/astro.js",
        				args = { "dev" },
        				cwd = "''${workspaceFolder}",
        				rootPath = "''${workspaceFolder}",
        				sourceMaps = true,
        				console = "integratedTerminal",
        				outFiles = {
        					"''${workspaceFolder}/dist/**/*.js",
        					"''${workspaceFolder}/.astro/**/*.ts"
        				},
        				resolveSourceMapLocations = {
        					"''${workspaceFolder}/dist/**/*.js",
        					"''${workspaceFolder}/.astro/**/*.ts"
        				},
        				skipFiles = {
        					"<node_internals>/**"
        				}
        			}
        		}

        		dap.configurations.astro = dap.configurations.typescript
      '';
    };

    "nvim-dap-ui" = {
      package = pkgs.vimPlugins.nvim-dap-ui;
      lazy = true;
      setupModule = "dapui";
      setupOpts = {
        controls.enabled = false;
        layouts = [
          {
            elements = [
              "scopes"
              "breakpoints"
              "stacks"
              "watches"
            ];
            size = 70;
            position = "right";
          }
          {
            elements = [
              "repl"
              "console"
            ];
            size = 10;
            position = "bottom";
          }
        ];
      };
      # fix statusline for dap-ui widgets
      after = ''
        vim.o.statusline="%f"
        vim.api.nvim_set_hl(0, "StatusLineNC", { link = "StatusLine" })
      '';
    };
  };
}
