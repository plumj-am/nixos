{
  pkgs,
  fenix,
  bacon-ls,
  system,
  ...
}:

{
  home.packages = [
    fenix.packages.${pkgs.system}.complete.toolchain
    pkgs.cargo-binstall
    pkgs.bacon
    bacon-ls.defaultPackage.${system}
    pkgs.cargo-careful
    pkgs.cargo-deny
    pkgs.cargo-fuzz
    pkgs.cargo-nextest
    pkgs.cargo-machete
    pkgs.cargo-workspaces
    pkgs.dioxus-cli
    pkgs.kondo
  ];
}
