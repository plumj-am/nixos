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
    { pkgs, lib, ... }:
    let
      inherit (lib.generators) toJSON;
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.karabiner-elements;

        xdg.config.files."karabiner/karabiner.json" = {
          generator = toJSON { };
          value = {
            profiles = singleton {
              # Disable built-in keyboard when Corne v4 connected.
              devices = [
                {
                  disable_built_in_keyboard_if_exists = true;
                  identifiers = {
                    is_keyboard = true;
                    product_id = 4;
                    vendor_id = 18003;
                  };
                }
              ];
              name = "Default profile";
              selected = true;
              virtual_hid_keyboard = {
                keyboard_type_v2 = "ansi";
              };
            };
          };
        };
      };
    };
in
{
  flake.modules.nixos.peripherals = peripheralsLinux;
  flake.modules.darwin.peripherals = peripheralsDarwin;
}
