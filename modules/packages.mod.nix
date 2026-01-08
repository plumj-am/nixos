let
  commonPackages =
    { pkgs, ... }:
    [
      pkgs.ast-grep
      pkgs.comma
      pkgs.curl
      pkgs.forgejo-cli
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
      pkgs.wrk
      pkgs.xh
    ];

  darwinPackages =
    { pkgs, ... }:
    [
      pkgs.raycast
      pkgs.karabiner-elements
    ];

  linuxPackages =
    { pkgs, ... }:
    [
      pkgs.gcc
      pkgs.gnumake
      pkgs.wget
    ];
in
{

  config.flake.modules.nixosModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = commonPackages pkgs ++ linuxPackages pkgs;
    };

  config.flake.modules.nixosModules.packages-extra-desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bitwarden-cli
        pkgs.deno
        pkgs.docker
        pkgs.docker-compose
        pkgs.exercism
        pkgs.moon
        pkgs.pnpm
        pkgs.proto
        pkgs.bitwarden-desktop
        pkgs.brave
        pkgs.obs-studio
        pkgs.thunderbird
        pkgs.wasistlos
      ];
    };

  config.flake.modules.nixosModules.packages-extra-wsl =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.bitwarden-cli
        pkgs.deno
        pkgs.docker
        pkgs.docker-compose
        pkgs.exercism
        pkgs.moon
        pkgs.pnpm
        pkgs.proto
      ];
    };

  config.flake.modules.darwinModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = commonPackages pkgs ++ darwinPackages pkgs;
    };
}
