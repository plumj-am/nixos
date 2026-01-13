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

  commonDevTools =
    { pkgs, ... }:
    [
      pkgs.bitwarden-cli
      pkgs.deno
      pkgs.docker
      pkgs.docker-compose
      pkgs.exercism
      pkgs.pnpm
      pkgs.deadnix
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

  desktopApps =
    { pkgs, ... }:
    [
      pkgs.bitwarden-desktop
      pkgs.brave
      pkgs.obs-studio
      pkgs.thunderbird
      pkgs.vesktop
      pkgs.wasistlos
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

  flake.modules.nixos.packages =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) flatten;
    in
    {
      environment.defaultPackages = [ ];
      environment.systemPackages =
        [
          (commonPackages pkgs)
          (linuxPackages pkgs)
        ]
        |> flatten;
    };

  flake.modules.nixos.packages-extra-desktop =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) flatten;
    in
    {
      environment.systemPackages =
        [
          (desktopApps pkgs)
          (commonDevTools pkgs)
        ]
        |> flatten;
    };

  flake.modules.nixos.packages-extra-wsl =
    { pkgs, ... }:
    {
      environment.systemPackages = commonDevTools pkgs;
    };

  flake.modules.darwin.packages =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) flatten;
    in
    {
      environment.defaultPackages = [ ];
      environment.systemPackages =
        [
          (commonPackages pkgs)
          (darwinPackages pkgs)
        ]
        |> flatten;
    };
}
