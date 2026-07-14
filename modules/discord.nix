{
  flake.modules.common.discord =
    # { pkgs, lib, ... }:
    # let
    # inherit (lib.lists) singleton;
    # in
    {
      hjem.extraModule = {
        # TODO: waiting for new version (broken by electron): <https://github.com/NixOS/nixpkgs/issues/542512>
        # packages = singleton pkgs.vesktop;
      };
    };
}
