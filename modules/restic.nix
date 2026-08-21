{
  flake.modules.nixos.restic =
    { config, pkgs, ... }:
    let
      inherit (config.networking) hostName;
      inherit (config.sops) secrets;
      inherit (config.s3.caches.garage) endpoint alias region;
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
            repository = "s3:http://${endpoint}/backups/${hostName}/${name}";
            passwordFile = secrets."restic/password".path;
            environmentFile = toString (
              pkgs.writeText "restic-garage-env" ''
                AWS_PROFILE=${alias}
                AWS_SHARED_CREDENTIALS_FILE=${config.s3.credentialsFile}
                AWS_REGION=${region}
              ''
            );
            extraOptions = [ "s3.bucket-lookup=path" ];
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
