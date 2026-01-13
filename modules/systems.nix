let
  commonModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.options) mkOption;
      inherit (lib.types) enum;
      inherit (lib.strings) splitString;
      inherit (lib.lists) last;
      inherit (config.myLib) mkConst;

    in
    {
      options = {
        os = mkConst <| last <| splitString "-" config.nixpkgs.hostPlatform.system;

        platform = mkOption {
          type = enum [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
            "x86_64-darwin"
          ];
          default = pkgs.system;
          example = "x86_64-linux";
          description = "The host platform (inferred from pkgs.system)";
        };

        type = mkOption {
          type = enum [
            "desktop"
            "server"
            "wsl"
          ];
          default = "server";
          example = "server";
          description = "The host system type";
        };

        isLinux = mkConst <| config.os == "linux";
        isDarwin = mkConst <| config.os == "darwin";
        isWsl = mkConst <| config.os == "wsl";
        isDesktop = mkConst <| config.type == "desktop";
        isServer = mkConst <| config.type == "server";
      };

      config.nixpkgs.hostPlatform = config.platform;
    };
in
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  flake.modules.nixos.system = commonModule;
  flake.modules.darwin.system = commonModule;
}
