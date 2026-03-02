let
  linuxUsersBase =
    {
      pkgs,
      config,
      ...
    }:
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

  linuxUsersExtra =
    { pkgs, config, ... }:
    let
      inherit (config.flake) keys;
    in
    {
      users.users = {
        anamana = {
          description = "Anamana";
          isNormalUser = true;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = [ keys.anamana ] ++ keys.admins;
        };
      };

      hjem.users = {
        anamana = {
          user = "anamana";
          directory = "/home/anamana";
          packages = [
            pkgs.sccache
            pkgs.git
            pkgs.direnv
          ];
        };
      };
    };

  darwinUsersBase =
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
in
{
  flake.modules.nixos.users = linuxUsersBase;
  flake.modules.darwin.users = darwinUsersBase;

  flake.modules.nixos.users-extra = linuxUsersExtra;
}
