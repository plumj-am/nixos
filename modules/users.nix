let
  linuxUsersBase =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.flake) keys;

      cfg = config.hjem.users;
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
            directory = "/home/${cfg.root.user}";
          };
          jam = {
            user = "jam";
            directory = "/home/${cfg.jam.user}";
          };
        };
      };
    };

  linuxUsersExtra =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) mkForce;
      inherit (lib.lists) singleton;
      inherit (config.flake) keys;

      cfg = config.hjem.users;
    in
    {
      users.groups.ssh = { };

      users.users = {
        anamana = {
          description = "Anamana";
          isNormalUser = true;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = singleton keys.anamana ++ keys.admins;
          extraGroups = singleton "ssh";
        };
      };

      hjem.users = {
        anamana = {
          user = "anamana";
          directory = "/home/${cfg.anamana.user}";
          packages = [
            pkgs.sccache
            pkgs.git
            pkgs.direnv
          ];
          xdg.cache.files = mkForce { };
          xdg.config.files = mkForce { };
          xdg.data.files = mkForce { };
          xdg.state.files = mkForce { };
          files = mkForce { };
        };
      };
    };

  darwinUsersBase =
    { pkgs, config, ... }:
    let
      inherit (config.flake) keys;

      home = "/Users/jam";
    in
    {
      system.primaryUser = "jam";

      users.users = {
        jam = {
          inherit home;
          description = "Jam";
          shell = pkgs.nushell;
          openssh.authorizedKeys.keys = keys.admins;
        };
      };

      hjem = {
        clobberByDefault = true;
        users.jam = {
          user = "jam";
          directory = home;
        };
      };
    };
in
{
  flake.modules.nixos.users = linuxUsersBase;
  flake.modules.darwin.users = darwinUsersBase;

  flake.modules.nixos.users-extra = linuxUsersExtra;
}
