lib: 
let
  inherit (lib) inputs;
in {
  class = "nixos";
  config = lib.nixosSystem' {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.wsl
      ./configuration.nix
    ];
  };
}