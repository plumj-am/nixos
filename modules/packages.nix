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
      pkgs.brave
      pkgs.obs-studio
      # pkgs.thunderbird
      pkgs.wasistlos
    ];

  flake.modules.nixos.packages-extra-cli =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.bitwarden-cli
      pkgs.deno
      pkgs.docker
      pkgs.docker-compose
      pkgs.pnpm
      pkgs.deadnix
      pkgs.treefmt
      # For experimental pipe-operators support.
      (pkgs.statix.overrideAttrs rec {
        src = pkgs.fetchFromGitHub {
          owner = "oppiliappan";
          repo = "statix";
          rev = "43681f0da4bf1cc6ecd487ef0a5c6ad72e3397c7";
          hash = "sha256-LXvbkO/H+xscQsyHIo/QbNPw2EKqheuNjphdLfIZUv4=";
        };

        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };
      })
    ];
}
