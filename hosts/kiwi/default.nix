lib: 
let
  inherit (lib) inputs collectNix remove;
in {
  class = "nixos";
  config = lib.nixosSystem' {
    system = "x86_64-linux";
    modules = [
      inputs.disko.nixosModules.disko
    ] ++ (collectNix ./. |> remove ./default.nix);
  };
}