{
  flake.modules.nixos.restic =
    { config, ... }:
    let
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;
    in
    {

      config = {
        sops.secrets."restic/password".sopsFile = ../secrets/services/restic.yaml;

        # Backup creation helper with restic to keep constants consistent.
        # Can be used like so:
        # `services.restic.backups.<service> = mkResticBackup "<service>" { <rest> }`
        myLib.mkResticBackup =
          name: rest:
          {
            repository = "s3:https://fsn1.your-objectstorage.com/plumjam/backups/${hostName}/${name}";
            passwordFile = secrets."restic/password".path;
            initialize = true;
            pruneOpts = [
              "--keep-daily 8"
              "--keep-weekly 5"
              "--keep-monthly 3"
            ];
          }
          // rest;
      };
    };
}
