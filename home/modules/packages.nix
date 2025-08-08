{
  pkgs,
  ...
}:
{
  programs.nix-index.enable = true;
  programs.bun.enable = true;

  home.packages = [
    pkgs.nodejs
    pkgs.python3
    pkgs.gcc
    pkgs.gnumake

    pkgs.steam-run
    pkgs.moon
    pkgs.proto
    pkgs.mprocs

    pkgs.claude-code
    pkgs.gemini-cli

    pkgs.comma

    pkgs.tree
    pkgs.hyperfine
    pkgs.curl
    pkgs.wget
  ];
}
