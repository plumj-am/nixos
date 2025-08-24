{ pkgs, ... }:
{
  home.packages = [
    pkgs.nodePackages.prettier
    pkgs.prettierd
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
          json = [
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
          sql = [ "sleek" ];
          python = [ "ruff_format" ];
        };
        format_after_save = {
          async = true;
          # lsp_format = "fallback"
        };
      };
    };
  };
}
