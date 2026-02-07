{ lib, ... }:
let
  inherit (lib.lists) singleton;

  peripheralsLinux =
    { pkgs, ... }:
    {
      hjem.extraModules = singleton {
        packages = [ pkgs.vial ];
      };

      services.libinput = {
        enable = true;
        mouse.leftHanded = true;
        touchpad.leftHanded = true;
      };

      # Udev rule for Vial keyboard access
      services.udev.extraRules = # udev
        ''
          # Universal Vial rule.
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
          # Specific rule for Corne v4.
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4653", ATTRS{idProduct}=="0004", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
        '';
    };

  peripheralsDarwin =
    { pkgs, ... }:
    {
      hjem.extraModules = singleton {
        packages = [ pkgs.karabiner-elements ];
      };
    };
in
{
  flake.modules.nixos.peripherals = peripheralsLinux;
  flake.modules.darwin.peripherals = peripheralsDarwin;
}
