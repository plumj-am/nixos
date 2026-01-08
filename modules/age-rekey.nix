{ self, config, lib, ... }: let
  inherit (lib) mkIf types;
in {
  options.age-rekey = {
    enable = lib.mkEnableOption "age-rekey";

    hostPubkey = lib.mkOption {
      type = types.str;
      example = "ssh-ed25519 ...";
      description = "Host public key for rekeying";
    };
    # TODO(1/2): Per OS type handling. Probably better to not use an option.
    typeOf = lib.mkOption {
      type = types.str;
      example = "linux";
      description = "OS type (linux|darwin) for age identity paths";
    };
  };

  config = mkIf config.age-rekey.enable {
    # TODO(2/2): Per OS type.
    age.identityPaths = [ "/root/.ssh/id" ];
    age.rekey = {
      hostPubkey       = config.age-rekey.hostPubkey;
      masterIdentities = [ (self + /yubikey.pub) ];
      localStorageDir  = self + "/secrets/rekeyed/${config.networking.hostName}";
      storageMode      = "local";
    };
  };
}
