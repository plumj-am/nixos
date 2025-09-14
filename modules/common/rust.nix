{ pkgs, fenix, bacon-ls, ... }:

{
  environment.systemPackages = [
    fenix.packages.${pkgs.system}.complete.toolchain # nightly
    # fenix.packages.${pkgs.system}.stable.toolchain # stable
    pkgs.cargo-binstall
    bacon-ls.defaultPackage.${pkgs.system}
    pkgs.cargo-careful
    pkgs.cargo-deny
    pkgs.cargo-fuzz
    pkgs.cargo-generate
    pkgs.cargo-nextest
    pkgs.cargo-machete
    pkgs.cargo-workspaces
    pkgs.dioxus-cli
    pkgs.kondo
  ];
}
