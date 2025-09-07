{ pkgs, lib, ... }:
{
  programs.nix-index.enable = true;

  programs.bun.enable = true;

  home.packages = [
    pkgs.nodejs
    pkgs.pnpm
    pkgs.python3

    pkgs.moon
    pkgs.proto
    pkgs.mprocs

    pkgs.claude-code
    pkgs.gemini-cli

    pkgs.comma

    pkgs.tree
    pkgs.hyperfine
    pkgs.curl
    pkgs.tokei
    pkgs.jq
		pkgs.ast-grep

    pkgs.vivid

    # starship-jj from crates.io
    (pkgs.rustPlatform.buildRustPackage rec {
      pname = "starship-jj";
      version = "0.5.1";
      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-tQEEsjKXhWt52ZiickDA/CYL+1lDtosLYyUcpSQ+wMo=";
      };
      cargoHash = "sha256-+rLejMMWJyzoKcjO7hcZEDHz5IzKeAGk1NinyJon4PY=";
      meta = {
        description = "Starship module for Jujutsu VCS";
        homepage = "https://crates.io/crates/starship-jj";
      };
    })

    # carapace
    pkgs.carapace
    pkgs.fish
    pkgs.zsh
    pkgs.inshellisense
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.wget
    pkgs.gcc
    pkgs.gnumake
    pkgs.steam-run
  ]
  ++ lib.optionals pkgs.stdenv.isDarwin [
    pkgs.arc-browser
    pkgs.alacritty
    pkgs.karabiner-elements
    pkgs.raycast
  ];
}
