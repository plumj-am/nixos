{ pkgs, keys, config, lib, ... }: let
  inherit (lib) mkIf types;
in {
  # "customUsers" to avoid conflicts with "users".
  options.customUsers = {
    enable = lib.mkEnableOption "users";

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

    buildUser = lib.mkEnableOption "build user (for CI/CD)";

    forgejoUser = lib.mkEnableOption "forgejo user for forgejo host";
  };

  config = mkIf config.customUsers.enable {
    age.secrets.password.rekeyFile = config.customUsers.passwordFile;

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
        extraGroups                 = config.customUsers.primaryUserExtraGroups;
      };

      build = mkIf config.customUsers.buildUser {
        description                 = "Build";
        isNormalUser                = true;
        createHome                  = false;
        openssh.authorizedKeys.keys = keys.all;
        extraGroups                 = [ "build" ];
      };

      forgejo = mkIf config.customUsers.forgejoUser {
        description                 = "Forgejo";
        createHome                  = false;
        openssh.authorizedKeys.keys = keys.admins;
      };
    };

    home-manager.users = {
      root = {};
      jam  = {};
    };
  };
}
