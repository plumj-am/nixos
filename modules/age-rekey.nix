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
  };

  config = mkIf config.age-rekey.enable {
    age.rekey = {
      hostPubkey       = config.age-rekey.hostPubkey;
      masterIdentities = [ (self + /yubikey.pub) ];
      localStorageDir  = self + "/secrets/rekeyed/${config.networking.hostName}";
      storageMode      = "local";
    };
  };
}
