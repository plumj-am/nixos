{
  flake.modules.nixos.users =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) optionalAttrs;
      inherit (config.networking) hostName;
      inherit (config.flake) keys;
    in
    {
      users.mutableUsers = false;

      users.users = {
        root = {
          shell = pkgs.nushell;
          hashedPasswordFile = config.age.secrets.password.path;
          openssh.authorizedKeys.keys = keys.admins;
        };

        jam = {
          description = "Jam";
          isNormalUser = true;
          shell = pkgs.nushell;
          hashedPasswordFile = config.age.secrets.password.path;
          openssh.authorizedKeys.keys = keys.admins;
        };
      }
      // optionalAttrs (hostName == "blackwell") {
        anamana = {
          description = "Anamana";
          isNormalUser = true;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = [ keys.anamana ] ++ keys.admins;
          packages = [
            pkgs.git
            pkgs.direnv
          ];
        };
      };

      hjem = {
        clobberByDefault = true;
        users = {
          root = {
            user = "root";
            directory = "/home/root";
          };
          jam = {
            user = "jam";
            directory = "/home/jam";
          };
        };
      };
    };

  flake.modules.darwin.users =
    { pkgs, config, ... }:
    let
      inherit (config.flake) keys;
    in
    {
      system.primaryUser = "jam";

      users.users = {
        jam = {
          home = "/Users/jam";
          description = "Jam";
          shell = pkgs.nushell;
          openssh.authorizedKeys.keys = keys.admins;
        };
      };

      hjem = {
        clobberByDefault = true;
        users.jam = {
          user = "jam";
          directory = "/Users/jam";
        };
      };
    };
}
