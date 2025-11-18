{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
		pkgs.ast-grep
    pkgs.comma
    pkgs.curl
    pkgs.hyperfine
    pkgs.moreutils
    pkgs.nodejs
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
		pkgs.bitwarden-cli
    pkgs.deno
		pkgs.docker
		pkgs.docker-compose
    pkgs.exercism
    pkgs.moon
    pkgs.pnpm
    pkgs.proto
    pkgs.python3
  ]
  ++ lib.optionals config.isDesktopNotWsl [
		pkgs.bitwarden-desktop
		pkgs.brave
    pkgs.obs-studio
    pkgs.thunderbird
    pkgs.vesktop
    pkgs.wasistlos
  ];
}
