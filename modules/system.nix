{ config, lib, ... }: let
  inherit (lib) last mkConst mkValue splitString;
in {
  options = {
    os = mkConst <| last <| splitString "-" config.nixpkgs.hostPlatform.system;

    isLinux  = mkConst <| config.os == "linux";
    isDarwin = mkConst <| config.os == "darwin";
    isWsl    = mkValue false;

    type = mkValue "server";

    isDesktop       = mkConst <| config.type == "desktop";
    isServer        = mkConst <| config.type == "server";
    isDesktopNotWsl = mkConst <| config.isDesktop && !config.isWsl;

    isGaming = mkValue false;
  };
}
