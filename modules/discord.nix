{ self, ... }:
{
  flake.commonModules.desktop = self.commonModules.discord;
  flake.commonModules.discord =
    # { pkgs, lib, ... }:
    # let
    # inherit (lib.lists) singleton;
    # in
    {
      # TODO: waiting for new version (broken by electron): <https://github.com/NixOS/nixpkgs/issues/542512>
      # environment.systemPackages = singleton pkgs.vesktop;
    };
}
