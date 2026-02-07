{ lib, ... }:
let
  inherit (lib.lists) singleton;

  mkHjemPackages = packages: {
    hjem.extraModules = singleton {
      inherit packages;
    };
  };

  packagesBase =
    { pkgs, ... }:
    {
      environment.defaultPackages = [ ];
    }
    // mkHjemPackages [
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
      pkgs.typos
      pkgs.uutils-coreutils-noprefix
      pkgs.sqld
      pkgs.sqlite
      pkgs.wrk
      pkgs.xh
    ];

  packagesExtraCli =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.bitwarden-cli
      pkgs.deno
      pkgs.docker
      pkgs.docker-compose
      pkgs.exercism
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

  packagesExtraGui =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.bitwarden-desktop
      pkgs.brave
      pkgs.obs-studio
      pkgs.thunderbird
      pkgs.wasistlos
    ];

  packagesExtraLinux =
    { pkgs, ... }:
    mkHjemPackages [
      pkgs.gcc
      pkgs.gnumake
      pkgs.wget
    ];
in
{
  flake.modules.nixos.packages = packagesBase;
  flake.modules.darwin.packages = packagesBase;

  flake.modules.nixos.packages-extra-linux = packagesExtraLinux;
  flake.modules.nixos.packages-extra-gui = packagesExtraGui;
  flake.modules.nixos.packages-extra-cli = packagesExtraCli;
}
