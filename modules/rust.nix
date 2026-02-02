let
  commonModule =
    { pkgs, ... }:
    {
      environment.sessionVariables = {
        CARGO_NET_GIT_FETCH_WITH_CLI = "true";
      };

      environment.systemPackages = [
        pkgs.cargo-binstall
        pkgs.cargo-nextest
        pkgs.dioxus-cli
      ];
    };

  rustDesktop =
    { pkgs, inputs }:
    {
      environment.systemPackages = [
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
          # Nightly.
          "cargo"
          "clippy"
          "miri"
          "rustc"
          "rust-analyzer"
          "rustfmt"
          "rust-std"
          "rust-src"
        ])
        pkgs.bacon
        pkgs.cargo-careful
        pkgs.cargo-deny
        pkgs.cargo-generate
        pkgs.cargo-machete
        pkgs.cargo-workspaces
        pkgs.cargo-outdated
        pkgs.evcxr
        pkgs.kondo
      ];
    };
in
{
  flake-file.inputs = {
    fenix = {
      url = "github:nix-community/fenix";

      inputs.nixpkgs.follows = "os";
    };
  };

  flake.modules.nixos.rust =
    { pkgs, inputs, ... }:
    {
      imports = [
        (commonModule { inherit pkgs; })
      ];

      environment.systemPackages = [
        (inputs.fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [
          # Nightly.
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

  flake.modules.nixos.rust-desktop =
    { pkgs, inputs, ... }:
    {
      imports = [
        (rustDesktop { inherit pkgs inputs; })
        (commonModule { inherit pkgs; })
      ];
    };

  flake.modules.darwin.rust-desktop =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      inherit (lib.strings) makeLibraryPath;
    in
    {
      imports = [
        (rustDesktop { inherit pkgs inputs; })
      ];
      environment.variables = {
        LIBRARY_PATH = makeLibraryPath [ pkgs.libiconv ];
      };
    };
}
