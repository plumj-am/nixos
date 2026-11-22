{ self, ... }:
{
  flake.nixosModules.desktop = self.nixosModules.peripherals;
  flake.nixosModules.peripherals =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.vial;

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

  flake.darwinModules.desktop = self.darwinModules.peripherals;
  flake.darwinModules.peripherals =
    { pkgs, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      environment.systemPackages = singleton pkgs.karabiner-elements;

      hjemModule = {
        xdg.config.files."karabiner/karabiner.json" = {
          generator = pkgs.writers.writeJSON "karabiner-karabiner.json";
          value = {
            profiles = singleton {
              # Disable built-in keyboard when Corne v4 connected.
              devices = singleton {
                disable_built_in_keyboard_if_exists = true;
                identifiers = {
                  is_keyboard = true;
                  product_id = 4;
                  vendor_id = 18003;
                };
              };
              name = "Default profile";
              selected = true;
              virtual_hid_keyboard.keyboard_type_v2 = "ansi";
            };
          };
        };
      };
    };
}
