{ self, ... }:
{
  flake.commonModules.default = self.commonModules.packages;
  flake.commonModules.packages =
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

  flake.nixosModules.default = self.nixosModules.packages;
  flake.nixosModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.gcc
        pkgs.gnumake
        pkgs.wget
      ];
    };

  flake.nixosModules.desktop.imports = [
    self.nixosModules.packages-gui
    self.nixosModules.packages-cli
  ];

  flake.nixosModules.packages-gui =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.obs-studio
        # pkgs.thunderbird
      ];
    };

  flake.nixosModules.packages-cli =
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
