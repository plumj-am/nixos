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
    pkgs.sqlite
  ]
  ++ lib.optionals config.isDesktop [
    pkgs.deno
    pkgs.moon
    pkgs.nodejs
    pkgs.pnpm
    pkgs.proto
    pkgs.python3
  ]
  ++ lib.optionals config.isDesktopNotWsl [
    pkgs.whatsapp-for-linux
    pkgs.thunderbird
  ];
}
