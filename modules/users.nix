{
  config.flake.modules.nixos.users =
    { pkgs, config, ... }:
    let
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
          extraGroups = [
            "wheel"
            "networkmanager"
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

  config.flake.modules.darwin.users =
    { pkgs, config, ... }:
    let
      inherit (config.flake) keys;
    in
    {
      system.primaryUser = "jam";

      users.users = {
        jam = {
          description = "Jam";
          shell = pkgs.nushell;
          openssh.authorizedKeys.keys = keys.admins;
        };
      };

      hjem = {
        clobberByDefault = true;
        users.jam = {
          user = "jam";
          directory = "/home/jam";
        };
      };
    };
}
