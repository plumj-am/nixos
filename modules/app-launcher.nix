{
  flake.modules.darwin.app-launcher =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.raycast;
    };
}
