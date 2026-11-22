{ self, ... }:
{
  flake.darwinModules.default = self.darwinModules.app-launcher;
  flake.darwinModules.app-launcher =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.raycast;
    };
}
