{ inputs, ... }:
{
  flake.nixosModules.iso =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton <| "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix";

      isoImage = {
        makeEfiBootable = true;
        makeUsbBootable = true;
        storeContents = singleton config.system.build.toplevel;
      };

      hardware = {
        enableAllHardware = true;
        enableAllFirmware = true;
      };

      nixpkgs.allowedUnfreePackages = [ ];

      users.users.root.initialHashedPassword = "";
      services.getty.autologinUser = "root";
    };
}
