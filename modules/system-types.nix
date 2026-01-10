let
  commonModule =
    { config, lib, ... }:
    let
      inherit (lib) types mkOption mkIf;
    in
    {
      options.operatingSystem = mkOption {
        type = types.enum [
          "linux"
          "darwin"
        ];
        default = "linux";
        example = "linux";
        description = "The host system operating system";
      };

      options.systemType = mkOption {
        type = types.enum [
          "desktop"
          "server"
        ];
        default = "server";
        example = "server";
        description = "The host system type";
      };

      options.isLinux = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the system is Linux";
      };

      options.isDarwin = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the system is Darwin/macOS";
      };

      options.isDesktop = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the system is a desktop";
      };

      options.isServer = mkOption {
        type = types.bool;
        default = false;
        description = "Whether the system is a server";
      };

      config.isLinux = mkIf (config.operatingSystem == "linux") true;
      config.isDarwin = mkIf (config.operatingSystem == "darwin") true;
      config.isDesktop = mkIf (config.systemType == "desktop") true;
      config.isServer = mkIf (config.systemType == "server") true;
    };
in
{
  config.flake.modules.nixos.system-types = commonModule;
  config.flake.modules.darwin.system-types = commonModule;
}
