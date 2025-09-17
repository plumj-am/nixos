{ lib, ... }: let
  inherit (lib) enabled;
in {
  security.sudo = enabled {
    execWheelOnly = true;
  };
}
