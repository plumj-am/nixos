{ pkgs, ... }:
{
  home.packages = [
    pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter
    pkgs.vscode-js-debug
    pkgs.gdb
  ];
  programs.nvf.settings.vim.lazy.plugins = {
    "nvim-dap" = {
      package = pkgs.vimPlugins.nvim-dap;
      lazy = true;
      after = ''
        local dap = require('dap')

        dap.defaults.codelldb.stepping_granularity = 'instruction'

        dap.adapters.codelldb = {
          type = 'executable',
          command = 'codelldb',
        }

        dap.adapters.gdb = {
          type = 'executable',
          command = 'gdb',
          args = { '-i', 'dap' }
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

        -- only for nasm
        dap.configurations.nasm = {
          {
            name = "Launch NASM (CodeLLDB)",
            type = "codelldb",
            request = "launch",
            program = function()
                local file_dir = vim.fn.expand('%:p:h') -- dir of current file
                local file = vim.fn.expand('%:t') -- filename without extension
                local source = vim.fn.expand('%:t:r') -- filename with extension

                vim.fn.system('mkdir -p ' .. file_dir .. '/target')
                -- assemble
                vim.fn.system('nasm -f elf64 -g -F dwarf ' .. file_dir .. source .. ' -o ' .. file_dir .. '/target/' .. file .. '.o')
                -- link
                vim.fn.system('ld ' .. file_dir .. '/target/' .. file .. '.o -o ' .. file_dir .. '/target/' .. file)
                -- path to exec
                return file_dir .. '/target/' .. source
            end,
            cwd = vim.fn.expand('%:p:h'),
            stopOnEntry = true,
            terminal = "integrated",
            initCommands = {
                "settings set target.x86-disassembly-flavor intel",
            },
            -- showDisassembly = "never",
            presentationHint = "normal",
            sourceLanguages = { "asm" },
          }
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

        -- open dapui on debugger start
        dap.listeners.before.attach.dapui_config = function()
          require("dapui").open()
        end
        dap.listeners.before.launch.dapui_config = function()
          require("dapui").open()
        end

        vim.keymap.set('n', '<leader>da', function()
            local word = vim.fn.expand('<cword>')
            if word and word ~= "" then
                local dapui = require('dapui')
                dapui.elements.watches.add(word)
            end
        end, { desc = 'Add default single LLDB formatted watch' })

        vim.keymap.set('n', '<F8>', function()
            local word = vim.fn.expand('<cword>')
            if word and word ~= "" then
                local dapui = require('dapui')
                dapui.elements.watches.add(word)
            end
        end, { desc = 'Add default single LLDB formatted watch' })

        vim.keymap.set('n', '<leader>dA', function()
            local word = vim.fn.expand('<cword>')
            if word and word ~= "" then
                local dapui = require('dapui')

                -- Format options - key maps to suffix
                local formats = {
                    d = ',d',  -- (d)ecimal
                    c = ',c',  -- (c)haracter
                    u = ',u',  -- (u)nsigned
                    b = ',b',  -- (b)inary
                    x = ',x',  -- he(x)
                    o = ',o',  -- (o)ctal
                    f = ',f',  -- (f)loat
                    p = ',p',  -- (p)ointer
                    s = ',s',  -- (s)tring
                    y = ',y',  -- b(y)tes
                    Y = ',Y',  -- b(Y)tes+ASCII
                }

                local help_text = '(d)ecimal (c)haracter (u)nsigned (b)inary he(x) (o)ctal (f)loat (p)ointer (s)tring b(y)tes b(Y)tes+ASCII'

                vim.ui.input({
                    prompt = 'Format for "' .. word .. '" - ' .. help_text .. ': ',
                    default = ""
                }, function(input)
                    if input and input ~= "" then
                        local char = input:sub(1, 1):lower()
                        local suffix = formats[char]

                        if suffix then
                            dapui.elements.watches.add(word .. suffix)
                            print('Added: ' .. word .. suffix)
                        else
                            print('Invalid format: ' .. char)
                        end
                    end
                end)
            else
                print('No word under cursor')
            end
        end, { desc = 'Add specific single LLDB formatted watch' })
        vim.keymap.set('n', '<F9>', function()
            local word = vim.fn.expand('<cword>')
            if word and word ~= "" then
                local dapui = require('dapui')

                -- Format options - key maps to suffix
                local formats = {
                    d = ',d',  -- (d)ecimal
                    c = ',c',  -- (c)haracter
                    u = ',u',  -- (u)nsigned
                    b = ',b',  -- (b)inary
                    x = ',x',  -- he(x)
                    o = ',o',  -- (o)ctal
                    f = ',f',  -- (f)loat
                    p = ',p',  -- (p)ointer
                    s = ',s',  -- (s)tring
                    y = ',y',  -- b(y)tes
                    Y = ',Y',  -- b(Y)tes+ASCII
                }

                local help_text = '(d)ecimal (c)haracter (u)nsigned (b)inary he(x) (o)ctal (f)loat (p)ointer (s)tring b(y)tes b(Y)tes+ASCII'

                vim.ui.input({
                    prompt = 'Format for "' .. word .. '" - ' .. help_text .. ': ',
                    default = ""
                }, function(input)
                    if input and input ~= "" then
                        local char = input:sub(1, 1):lower()
                        local suffix = formats[char]

                        if suffix then
                            dapui.elements.watches.add(word .. suffix)
                            print('Added: ' .. word .. suffix)
                        else
                            print('Invalid format: ' .. char)
                        end
                    end
                end)
            else
                print('No word under cursor')
            end
        end, { desc = 'Add specific single LLDB formatted watch' })
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
              {
                id = "scopes";
                size = 0.25;
              }
              {
                id = "breakpoints";
                size = 0.25;
              }
              {
                id = "stacks";
                size = 0.25;
              }
              {
                id = "watches";
                size = 0.25;
              }
            ];
            size = 71;
            position = "right";
          }
          {
            elements = [
              {
                id = "repl";
                size = 0.5;
              }
              {
                id = "console";
                size = 0.5;
              }
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

    # cant get it working well in nasm at least
    "nvim-dap-virtual-text" = {
      package = pkgs.vimPlugins.nvim-dap-virtual-text;
      enabled = true;
      lazy = true;
      setupModule = "nvim-dap-virtual-text";
      setupOpts = {
        enabled = true;
        enabled_commands = true;
        highlight_new_as_changed = true;
        commented = true;
        virt_text_win_col = 80;
      };
      after = ''
        require("nvim-dap-virtual-text").setup({
          enabled = true;
          enabled_commands = true;
          highlight_new_as_changed = true;
          commented = true;
          virt_text_win_col = 80;
        })
      '';
    };
  };
}
