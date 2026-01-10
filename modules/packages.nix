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

  config.flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
      environment.systemPackages = commonPackages pkgs ++ linuxPackages pkgs;
    };

  config.flake.modules.nixos.packages-extra-desktop =
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
        pkgs.vesktop
        pkgs.wasistlos
      ];
    };

  config.flake.modules.nixos.packages-extra-wsl =
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

  config.flake.modules.darwin.packages =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
      environment.systemPackages = commonPackages pkgs ++ darwinPackages pkgs;
    };
}
