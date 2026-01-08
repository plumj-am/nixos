{ config, lib, ... }: let
  inherit (lib) enabled mkIf types;
in {
  options.openssh = {
    enable = lib.mkEnableOption "openssh";

    idFile = lib.mkOption {
      type = types.path;
      example = "/run/agenix/id";
      description = "Path to the secret SSH id file";
    };
  };

  config = mkIf config.openssh.enable {
    age.secrets.id.rekeyFile = config.openssh.idFile;
    services.openssh = enabled {
      hostKeys = [{
        type = "ed25519";
        path = config.age.secrets.id.path;
      }];
      settings = {
        PasswordAuthentication       = false;
        KbdInteractiveAuthentication = false;
        AcceptEnv                    = [ "SHELLS" "COLORTERM" ];
      };
    };

  };
}
