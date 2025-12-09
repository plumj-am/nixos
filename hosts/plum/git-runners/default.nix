{ pkgs, lib, config, inputs, ... }: let
  inherit (lib) enabled;
in {
  age.secrets.forgejoRunnerToken.rekeyFile = ./forgejo-runner-token.age;
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.${config.networking.hostName} = enabled {
      name         = config.networking.hostName;
      tokenFile    = config.age.secrets.forgejoRunnerToken.path;
      url          = "https://git.plumj.am/";
      labels       = [
        "plum:host"
        "docpad-infra:host"
        "self-hosted:host"
      ];

      settings.cache.enabled = false;

      hostPackages = [
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [ # Nightly.
          "cargo"
          "clippy"
          "miri"
          "rustc"
          "rust-analyzer"
          "rustfmt"
          "rust-std"
          "rust-src"
        ])
        pkgs.bash
        pkgs.curl
        pkgs.docker
        pkgs.docker-compose
        pkgs.forgejo-cli
        pkgs.gcc # Fixes cc linker not found errors.
        pkgs.git
        pkgs.gnutar # For cache processes.
        pkgs.gzip   # ...
        pkgs.just
        pkgs.nix
        pkgs.nodejs
        pkgs.nushell
        pkgs.opencode
        pkgs.openssl
        pkgs.pkg-config
        pkgs.ripgrep
        pkgs.sqlx-cli
        pkgs.which
        pkgs.xz
      ];
    };
  };
}
