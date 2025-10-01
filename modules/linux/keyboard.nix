{ pkgs, lib, config, ... }: let
  inherit (lib) mkIf;
in mkIf config.isDesktopNotWsl {
  environment.systemPackages = [ pkgs.vial ];

  # Udev rule for Vial keyboard access
  services.udev.extraRules = ''
    # Universal Vial rule.
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    # Specific rule for Corne v4.
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="4653", ATTRS{idProduct}=="0004", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';
}
