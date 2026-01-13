let
  commonModule =
    { config, lib, ... }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.modules) mkIf;
      inherit (lib.types) enum bool;
    in
    {
      options.operatingSystem = mkOption {
        type = enum [
          "linux"
          "darwin"
        ];
        default = "linux";
        example = "linux";
        description = "The host system operating system";
      };

      options.systemPlatform = mkOption {
        type = enum [
          "x86_64-linux"
          "aarch64-darwin"
        ];
        example = "x86_64-linux";
        description = "The host platform";
      };

      options.systemType = mkOption {
        type = enum [
          "desktop"
          "server"
          "wsl"
        ];
        default = "server";
        example = "server";
        description = "The host system type";
      };

      options.isLinux = mkOption {
        type = bool;
        default = false;
        description = "Whether the system is Linux";
      };

      options.isDarwin = mkOption {
        type = bool;
        default = false;
        description = "Whether the system is Darwin/macOS";
      };

      options.isDesktop = mkOption {
        type = bool;
        default = false;
        description = "Whether the system is a desktop";
      };

      options.isServer = mkOption {
        type = bool;
        default = false;
        description = "Whether the system is a server";
      };

      options.isWsl = mkOption {
        type = bool;
        default = false;
        description = "Whether the system is a wsl";
      };

      config.isLinux = mkIf (config.operatingSystem == "linux") true;
      config.isDarwin = mkIf (config.operatingSystem == "darwin") true;
      config.isDesktop = mkIf (config.systemType == "desktop") true;
      config.isServer = mkIf (config.systemType == "server") true;
      config.isWsl = mkIf (config.systemType == "wsl") true;

      config.nixpkgs.hostPlatform.system = config.systemPlatform;
    };
in
{
  flake.modules.nixos.system-types = commonModule;
  flake.modules.darwin.system-types = commonModule;
}
