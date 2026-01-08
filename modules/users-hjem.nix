{ pkgs, keys, config, lib, self, inputs, ... }: let
  inherit (lib) mkIf types;
in {
  options.customUsersHjem = {
    enable = lib.mkEnableOption "hjem users (for dendritic hosts)";

    passwordFile = lib.mkOption {
      type = types.path;
      example = "/run/agenix/password";
      description = "Path to the password secret file";
    };

    primaryUserExtraGroups = lib.mkOption {
      type = with types; listOf str;
      default = [ "wheel" ];
      example = [ "wheel" "networkmanager" "docker" ];
      description = "Extra groups for jam";
    };
  };

  config = mkIf config.customUsersHjem.enable {
    age.secrets.password.rekeyFile = config.customUsersHjem.passwordFile;

    # Pass arguments to hjem modules
    hjem.specialArgs = {
      inherit inputs;
      theme = config.theme;
      isDesktop = config.type == "desktop";
      isServer = config.type == "server";
      isGaming = config.isGaming or false;
      secrets = builtins.mapAttrs (name: secret: secret) config.age.secrets;
    };

    # Propagate all homeModules to all hjem users
    # Append modules to make theme and other NixOS values available as config options
    home.extraModules = builtins.attrValues self.modules.homeModules ++ [
      # First, define the options
      ({ lib, ... }: {
        options.theme = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Theme configuration from NixOS";
        };
        options.isDesktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is a desktop system";
        };
        options.isServer = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is a server system";
        };
        options.isGaming = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether this is a gaming system";
        };
      })
      # Then, set them from the NixOS config (via specialArgs)
      ({ lib, theme, isDesktop, isServer, isGaming, ... }: {
        config.theme = theme;
        config.isDesktop = isDesktop;
        config.isServer = isServer;
        config.isGaming = isGaming;
      })
    ];

    users.users = {
      root = {
        shell                       = pkgs.nushell;
        hashedPasswordFile          = config.age.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
      };

      jam = {
        description                 = "Jam";
        isNormalUser                = true;
        shell                       = pkgs.nushell;
        hashedPasswordFile          = config.age.secrets.password.path;
        openssh.authorizedKeys.keys = keys.admins;
        extraGroups                 = config.customUsersHjem.primaryUserExtraGroups;
      };
    };

    hjem.users = {
      root = {
        user = "root";
        directory = "/home/root";
      };
      jam  = {
        user = "jam";
        directory = "/home/jam";
      };
    };
  };
}
