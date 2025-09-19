{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.comma
    pkgs.tree
    pkgs.hyperfine
    pkgs.curl
    pkgs.tokei
		pkgs.ast-grep
  ]
  ++ lib.optionals config.isDesktop [
    pkgs.nodejs
    pkgs.deno
    pkgs.pnpm
    pkgs.python3

    pkgs.gemini-cli

    pkgs.moon
    pkgs.proto
  ]
  ++ lib.optionals config.isLinux [
    pkgs.wget
    pkgs.gcc
    pkgs.gnumake
  ];
}
