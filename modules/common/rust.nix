{ config, lib, pkgs, fenix, bacon-ls, ... }:
{
  environment.systemPackages = [
    # [1/2] For Forgejo Action runners.
    pkgs.cargo-binstall
    pkgs.cargo-nextest
    pkgs.dioxus-cli
  ]
  ++ lib.optionals config.isDesktop [
    (fenix.packages.${pkgs.system}.complete.withComponents [ # Nightly.
      "cargo"
      "clippy"
      "miri"
      "rustc"
      "rust-analyzer"
      "rustfmt"
      "rust-std"
      "rust-src"
    ])
    bacon-ls.defaultPackage.${pkgs.system}
    pkgs.cargo-careful
    pkgs.cargo-deny
    pkgs.cargo-fuzz
    pkgs.cargo-generate
    pkgs.cargo-machete
    pkgs.cargo-workspaces
    pkgs.cargo-outdated
    pkgs.kondo
  ]
  ++ lib.optionals config.isServer [
    # [1/2] For Forgejo Action runners.
    (fenix.packages.${pkgs.system}.complete.withComponents [ # Nightly.
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
