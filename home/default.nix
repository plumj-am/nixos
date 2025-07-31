{
  pkgs,
  fenix,
  system,
  nvf,
  bacon-ls,
  ...
}:

{
  imports = [
    nvf.homeManagerModules.default
    ./modules/common.nix
    ./modules/packages/development.nix
    ./modules/packages/system.nix
    ./modules/packages/rust.nix
    ./modules/programs
    ./modules/shell
  ];

  _module.args = {
    inherit
      pkgs
      system
      fenix
      nvf
      bacon-ls
      ;
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;

}
