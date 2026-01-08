{
  config.flake.modules.homeModules.rust =
    { pkgs, lib, config, inputs, ... }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.strings) makeLibraryPath;
      inherit (pkgs.stdenv) hostPlatform;
    in
    {
      environment.sessionVariables = {
        CARGO_NET_GIT_FETCH_WITH_CLI = "true";

        LIBRARY_PATH = mkIf hostPlatform.isDarwin <| makeLibraryPath [ pkgs.libiconv ];
      };

      packages = [
        # [1/2] For Forgejo Action runners.
        pkgs.cargo-binstall
        pkgs.cargo-nextest
        pkgs.dioxus-cli
      ]
      ++ lib.optionals config.isDesktop [
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
        pkgs.cargo-careful
        pkgs.cargo-deny
        pkgs.cargo-generate
        pkgs.cargo-machete
        pkgs.cargo-workspaces
        pkgs.cargo-outdated
        pkgs.kondo
      ]
      ++ lib.optionals config.isServer [
        # [2/2] For Forgejo Action runners.
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [ # Nightly.
          "cargo"
          "clippy"
          "miri"
          "rustc"
          "rustfmt"
          "rust-std"
          "rust-src"
        ])
      ];
    };
}
