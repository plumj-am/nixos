{ pkgs, ... }:
{
  home.packages = [
    pkgs.stylua
    pkgs.nodePackages.prettier
    pkgs.prettierd
    pkgs.nixfmt-rfc-style
    pkgs.nufmt
    pkgs.dprint
    pkgs.ruff
    pkgs.sleek
    pkgs.taplo
    pkgs.mdformat
  ];

  programs.nvf.settings.vim.formatter = {
    conform-nvim = {
      enable = true;
      setupOpts = {
        formatters = {
          mdformat = {
            append_args = [
              "--number"
              "--wrap"
              "80"
            ];
          };
        };
        formatters_by_ft = {
          astro = [
            "prettierd"
            "prettier"
          ];
          go = [
            "gofumpt"
            "goimports"
          ];
          javascript = [
            "prettierd"
            "prettier"
          ];
          javascriptreact = [
            "prettierd"
            "prettier"
          ];
          typescript = [
            "prettierd"
            "prettier"
          ];
          typescriptreact = [
            "prettierd"
            "prettier"
          ];
          json = [
            "prettierd"
            "prettier"
          ];
          svelte = [
            "prettierd"
            "prettier"
          ];
          vue = [
            "prettierd"
            "prettier"
          ];
          yaml = [
            "prettierd"
            "prettier"
          ];
          markdown = [ "mdformat" ];
          toml = [ "taplo" ];
          lua = [ "stylua" ];
          sql = [ "sleek" ];
          python = [ "ruff_format" ];
          rust = [ "rustfmt" ];
          # nu = [ "nufmt" ];
          nix = [ "nixfmt" ];
        };
        format_after_save = {
          async = true;
          # lsp_format = "fallback"
        };
      };
    };
  };
}
