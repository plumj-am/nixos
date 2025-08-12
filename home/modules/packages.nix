{
  pkgs,
  lib,
  ...
}:
{
  programs.nix-index.enable = true;
  programs.bun.enable = true;

  home.packages = [
    pkgs.nodejs
    pkgs.python3

    pkgs.moon
    pkgs.proto
    pkgs.mprocs

    pkgs.claude-code
    pkgs.gemini-cli

    pkgs.comma

    pkgs.tree
    pkgs.hyperfine
    pkgs.curl
    pkgs.tokei
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.wget
    pkgs.gcc
    pkgs.gnumake
    pkgs.steam-run
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    pkgs.arc-browser
    pkgs.alacritty
    pkgs.karabiner-elements
    pkgs.raycast
  ];
}
