{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
		pkgs.ast-grep
    pkgs.comma
    pkgs.curl
    pkgs.hyperfine
    pkgs.moreutils
		pkgs.openssl
		pkgs.rsync
    pkgs.tokei
    pkgs.tree
    pkgs.typos
    pkgs.uutils-coreutils-noprefix
  ]
  ++ lib.optionals config.isDesktop [
    pkgs.deno
    pkgs.gemini-cli
    pkgs.moon
    pkgs.nodejs
    pkgs.pnpm
    pkgs.proto
    pkgs.python3
    pkgs.sqlite
  ]
  ++ lib.optionals config.isLinux [
    pkgs.gcc
    pkgs.gnumake
    pkgs.wget
  ];
}
