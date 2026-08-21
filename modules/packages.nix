{
  flake.modules.common.packages =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
      environment.systemPackages = [
        pkgs.ast-grep
        pkgs.curl
        pkgs.hyperfine
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
    };

  flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gcc
        pkgs.gnumake
        pkgs.wget
      ];
    };

  flake.modules.nixos.packages-gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.obs-studio
        pkgs.thunderbird
      ];
    };

  flake.modules.nixos.packages-cli =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.deno
        pkgs.docker
        pkgs.docker-compose
        pkgs.pnpm
        pkgs.deadnix
        pkgs.treefmt
        pkgs.statix
      ];
    };
}
