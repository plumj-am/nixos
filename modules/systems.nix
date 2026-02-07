let
  systemsBase =
    {
      config,
      lib,
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
    };
in
{
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];

  flake.modules.nixos.systems = systemsBase;
  flake.modules.darwin.systems = systemsBase;
}
