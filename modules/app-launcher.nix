{ self, ... }:
{
  flake.modules.darwin.default = self.modules.darwin.app-launcher;
  flake.modules.darwin.app-launcher =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.raycast;
    };
}
