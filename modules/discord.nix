{
  flake.modules.common.discord =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule = {
        packages = singleton pkgs.vesktop;
      };
    };
}
