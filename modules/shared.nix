{ self, config, inputs, lib, pkgs, keys, ... }: let
  inherit (lib) enabled mkIf optionalAttrs;
in {
  # Common user configuration
  users.users.james = {
    shell = pkgs.nushell;

  } // optionalAttrs config.isLinux {
    isNormalUser = true;
    extraGroups  = [ "wheel" ];

    openssh.authorizedKeys.keys = [ keys.james ];
  } // optionalAttrs config.isDarwin {
    name = "james";
    home = "/Users/james";
  };

  # Home Manager common config (Linux only)
  home-manager = mkIf config.isLinux {
    users.james = {};
    sharedModules = [{
      home.stateVersion     = "24.11";
      programs.home-manager = enabled;
    }];
  };
}
