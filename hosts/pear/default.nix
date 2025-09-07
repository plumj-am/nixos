lib: 
let
  inherit (lib) inputs collectNix remove;
in {
  class = "nixos";
  config = lib.nixosSystem' {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.wsl
    ] ++ (collectNix ./. |> remove ./default.nix);
  };
}