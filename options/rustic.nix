{ self, ... }:
{
  flake.nixosModules.rustic = self.nixosModules.rustic-options;
  flake.nixosModules.rustic-options =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrsToList;
      inherit (lib.options) mkOption;
      inherit (lib.strings) optionalString;
      inherit (lib.types) anything attrsOf;
      inherit (config.networking) hostName;

      cfg = config.services.rustic;
    in
    {
      options.helpers.rustic = mkOption {
        type = attrsOf anything;
        default = { };
        description = "Rustic backup creation helpers";
      };

      config = {
        assertions = mapAttrsToList (name: backup: {
          assertion = backup.paths != [ ] || backup.pruneOpts != [ ] || backup.checkOpts != [ ];
          message = "services.rustic.backups.${name} has nothing to do (no paths, pruneOpts, or checkOpts).";
        }) cfg.backups;

        helpers.rustic.mkBackup =
          name: rest:
          {
            package = pkgs.rustic;
            environmentFile =
              toString
              <| pkgs.writeText "rustic-s3-env" ''
                RUSTIC_REPOSITORY="opendal:s3"
                ${optionalString (cfg.passwordFile != null) ''RUSTIC_PASSWORD_FILE="${cfg.passwordFile}"''}

                OPENDAL_BUCKET="${cfg.bucket}"
                OPENDAL_ROOT="/${hostName}/${name}"
                OPENDAL_ENDPOINT="http://${cfg.endpoint}"
                OPENDAL_REGION="${cfg.region}"

                AWS_PROFILE=${cfg.alias}
                ${optionalString (cfg.credentialsFile != null) "AWS_SHARED_CREDENTIALS_FILE=${cfg.credentialsFile}"}
                AWS_REGION=${cfg.region}
              '';
            initialize = true;
            pruneOpts = [
              "--keep-daily 8"
              "--keep-weekly 5"
              "--keep-monthly 3"
            ];
            runCheck = true;
          }
          // rest;
      };
    };
}
