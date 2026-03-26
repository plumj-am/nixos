{
  flake.modules.darwin.app-launcher =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModules = singleton {
        packages = [ pkgs.raycast ];
      };
    };
}
