{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
		pkgs.ast-grep
		pkgs.brave
    pkgs.comma
    pkgs.curl
    pkgs.hyperfine
    pkgs.moreutils
		pkgs.openssl
		pkgs.pv
		pkgs.rsync
    pkgs.tokei
    pkgs.tree
    pkgs.turso-cli
    pkgs.typos
    pkgs.uutils-coreutils-noprefix
    pkgs.sqld
    pkgs.sqlite
    pkgs.xh
  ]
  ++ lib.optionals config.isDesktop [
		pkgs.bitwarden-desktop
		pkgs.bitwarden-cli
    pkgs.deno
    pkgs.moon
    pkgs.nodejs
    pkgs.pnpm
    pkgs.proto
    pkgs.python3
  ]
  ++ lib.optionals config.isDesktopNotWsl [
    pkgs.obs-studio
    pkgs.thunderbird
    pkgs.vesktop
    pkgs.wasistlos
  ];
}
