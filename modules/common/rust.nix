{ config, lib, pkgs, fenix, ... }:
{
  environment.systemPackages = [
    # [1/2] For Forgejo Action runners.
    pkgs.cargo-binstall
    pkgs.cargo-nextest
    pkgs.dioxus-cli
  ]
  ++ lib.optionals config.isDesktop [
    (fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [ # Nightly.
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
    (fenix.packages.${pkgs.stdenv.hostPlatform.system}.complete.withComponents [ # Nightly.
      "cargo"
      "clippy"
      "miri"
      "rustc"
      "rustfmt"
      "rust-std"
      "rust-src"
    ])
  ];
}
