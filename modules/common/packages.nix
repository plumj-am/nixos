{ config, pkgs, lib, ... }:
let
  inherit (lib) enabled;
in
{
  environment.systemPackages = [
    pkgs.nodejs
    pkgs.deno
    pkgs.pnpm
    pkgs.python3

    pkgs.moon
    pkgs.proto
    pkgs.mprocs

    pkgs.gemini-cli

    pkgs.comma

    pkgs.tree
    pkgs.hyperfine
    pkgs.curl
    pkgs.tokei
		pkgs.ast-grep

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
    pkgs.inshellisense
  ]
  ++ lib.optionals config.isLinux [
    pkgs.wget
    pkgs.gcc
    pkgs.gnumake
    pkgs.steam-run
  ]
  ++ lib.optionals config.isDarwin [
    pkgs.arc-browser
    pkgs.alacritty
    pkgs.karabiner-elements
    pkgs.raycast
  ];

  home-manager.sharedModules = [{
    programs.nix-index = enabled;
    programs.bun = enabled;
    programs.claude-code = enabled;
    programs.jq = enabled;
    programs.vivid = enabled;
    
    # Carapace stuff
    programs.carapace = enabled;
    programs.fish     = enabled;
    programs.zsh      = enabled;
  }];
}
