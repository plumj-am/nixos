{ self, ... }:
{
  flake.modules.common.default = self.modules.common.packages;
  flake.modules.common.packages =
    { pkgs, ... }:
    {
      shellAliases.wrk = "oha";

      environment.systemPackages = [
        pkgs.ast-grep
        pkgs.curl
        pkgs.hyperfine
        pkgs.nodejs
        pkgs.openssl
        pkgs.rsync
        pkgs.tokei
        pkgs.typos
        pkgs.uutils-coreutils-noprefix
        pkgs.uutils-diffutils
        pkgs.uutils-findutils
        pkgs.sqld
        pkgs.sqlite
        pkgs.oha
        pkgs.xh
      ];
    };

  flake.modules.nixos.default = self.modules.nixos.packages;
  flake.modules.nixos.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gcc
        pkgs.gnumake
        pkgs.wget
      ];
    };

  flake.modules.nixos.desktop.imports = [
    self.modules.nixos.packages-gui
    self.modules.nixos.packages-cli
  ];

  flake.modules.nixos.packages-gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.obs-studio
        # pkgs.thunderbird
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
