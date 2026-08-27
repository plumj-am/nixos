{ self, ... }:
{
  flake.modules.nixos.default = self.modules.nixos.users;
  flake.modules.nixos.users =
    {
      pkgs,
      config,
      ...
    }:
    let
      inherit (config.flake) entities;

      cfg = config.hjem.users;
    in
    {
      users.mutableUsers = false;
      environment.etc."shells".enable = false;

      users.users = {
        root = {
          shell = pkgs.nushell;
          hashedPasswordFile = config.sops.secrets.password.path;
          openssh.authorizedKeys.keys = entities.sshKeysAdmins;
        };

        jam = {
          description = "Jam";
          isNormalUser = true;
          shell = pkgs.nushell;
          hashedPasswordFile = config.sops.secrets.password.path;
          openssh.authorizedKeys.keys = entities.sshKeysAdmins;
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

  flake.modules.darwin.default = self.modules.darwin.users;
  flake.modules.darwin.users =
    { pkgs, config, ... }:
    let
      inherit (config.flake) entities;

      cfg = config.users.users.jam;
    in
    {
      system.primaryUser = "jam";

      users.users = {
        jam = {
          home = "/Users/jam";
          description = "Jam";
          shell = pkgs.nushell;
          openssh.authorizedKeys.keys = entities.sshKeysAdmins;
        };
      };

      hjem = {
        clobberByDefault = true;
        users.jam = {
          user = config.system.primaryUser;
          directory = cfg.home;
        };
      };
    };

  flake.modules.nixos.users-grove-systems =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.modules) mkForce;
      inherit (lib.lists) singleton;
      inherit (config.flake) entities;

      cfg = config.hjem.users;
    in
    {
      users.users = {
        ${entities.people.anamana.userName} = {
          description = entities.people.anamana.fullName;
          isNormalUser = true;
          shell = pkgs.bash;
          openssh.authorizedKeys.keys = singleton entities.sshKeys.anamana ++ entities.sshKeysAdmins;
          extraGroups = entities.people.anamana.extraGroups;
        };
      };

      hjem.users = {
        ${entities.people.anamana.userName} = {
          user = entities.people.anamana.userName;
          directory = "/home/${cfg.anamana.user}";
          packages = [
            pkgs.gitMinimal
            pkgs.direnv
            inputs.cade.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];
          xdg.cache.files = mkForce { };
          xdg.config.files = mkForce { };
          xdg.data.files = mkForce { };
          xdg.state.files = mkForce { };
          files = mkForce { };
          systemd.enable = false;
        };
      };
    };
}
