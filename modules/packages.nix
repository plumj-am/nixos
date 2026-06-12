let
  mkHjemPackages = packages: {
    hjem.extraModule = {
      inherit packages;
    };
  };
in
{
  flake.modules.common.packages =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
    }
    // mkHjemPackages [
      pkgs.ast-grep
      pkgs.curl
      pkgs.hyperfine
      pkgs.moreutils
      pkgs.nodejs
      pkgs.openssl
      pkgs.pv
      pkgs.rsync
      pkgs.tokei
      pkgs.tree
      pkgs.typos
      pkgs.uutils-coreutils-noprefix
      pkgs.sqld
      pkgs.sqlite
      pkgs.wrk
      pkgs.xh
    ];

  flake.modules.nixos.packages-extra-linux =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.gcc
      pkgs.gnumake
      pkgs.wget
    ];

  flake.modules.nixos.packages-extra-gui =
    { pkgs, ... }:
    mkHjemPackages [
      # pkgs.brave
      pkgs.obs-studio
      pkgs.thunderbird
      pkgs.nextcloud-client
    ];

  flake.modules.nixos.packages-extra-cli =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.deno
      pkgs.docker
      pkgs.docker-compose
      pkgs.pnpm
      pkgs.deadnix
      pkgs.treefmt
      pkgs.statix
    ];
}
