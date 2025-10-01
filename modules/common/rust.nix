{ config, lib, pkgs, fenix, bacon-ls, ... }: let
  inherit (lib) mkIf;
in
{
  environment.systemPackages = mkIf config.isDesktop [
    (fenix.packages.${pkgs.system}.complete.withComponents [ # nightly
      "cargo"
      "clippy"
      "miri"
      "rustc"
      "rust-analyzer"
      "rustfmt"
      "rust-std"
      "rust-src"
    ])
    pkgs.cargo-binstall
    bacon-ls.defaultPackage.${pkgs.system}
    pkgs.cargo-careful
    pkgs.cargo-deny
    pkgs.cargo-fuzz
    pkgs.cargo-generate
    pkgs.cargo-nextest
    pkgs.cargo-machete
    pkgs.cargo-workspaces
    pkgs.cargo-outdated
    pkgs.dioxus-cli
    pkgs.kondo
  ];
}
