{
  pkgs,
  fenix,
  system,
  ...
}:

{
  imports = [
    ./modules/common.nix
    ./modules/packages/development.nix
    ./modules/packages/system.nix
    ./modules/packages/rust.nix
    ./modules/programs
    ./modules/shell
    ./modules/dotfiles.nix
  ];

  _module.args = {
    inherit
      pkgs
      system
      fenix
      ;
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
