{ self, inputs, ... }:
{
  config.flake.modules.homeModules.home =
    { config, lib, pkgs, ... }:
    let
      inherit (lib.modules) mkAliasOptionModule;
      inherit (lib.options) mkOption;
      inherit (lib.types) bool;
    in
    {
      imports = [
        (mkAliasOptionModule [ "programs" ] [ "rum" "programs" ])
        (mkAliasOptionModule [ "desktops" ] [ "rum" "desktops" ])
        (mkAliasOptionModule [ "misc" ] [ "rum" "misc" ])
      ];

      config = {
        xdg.cache.directory = "${config.directory}/.cache";
        xdg.config.directory = "${config.directory}/.config";
        xdg.data.directory = "${config.directory}/.local/share";
        xdg.state.directory = "${config.directory}/.local/state";
      };
    };

  config.flake.modules.nixosModules.home =
    { lib, self, ... }:
    let
      inherit (lib.modules) mkAliasOptionModule;
    in
    {
      imports = [
        (mkAliasOptionModule [ "home" ] [ "hjem" ])
      ];

      # Note: home.extraModules is set by users-hjem.nix to all homeModules
      # Note: inputs.home.nixosModules.default is already included in mkNixos'
    };

  config.flake.modules.darwinModules.home =
    { lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkAliasOptionModule;
    in
    {
      imports = [
        inputs.home.darwinModules.default
        (mkAliasOptionModule [ "home" ] [ "hjem" ])

        { home.extraModules = singleton self.modules.homeModules.home; }
      ];

    };
}
