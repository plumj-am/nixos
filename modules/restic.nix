{
  flake.modules.nixos.rustic =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      inherit (lib.options) mkOption mkPackageOption;
      inherit (lib.meta) getExe;
      inherit (lib.attrsets)
        mapAttrs'
        nameValuePair
        optionalAttrs
        filterAttrs
        mapAttrsToList
        ;
      inherit (lib.strings) concatStringsSep escapeShellArg optionalString;
      inherit (lib.types)
        nullOr
        str
        bool
        listOf
        attrsOf
        submodule
        ;
      inherit (lib.lists) optional singleton;

      inherit (config.networking) hostName;
      inherit (config.sops) secrets;
      inherit (config.s3.caches.garage) endpoint alias region;
      inherit (utils.systemdUtils.unitOptions) unitOption;
    in
    {
      options.services.rustic.backups = mkOption {
        default = { };
        description = "Periodic backups to create with rustic.";
        type =
          attrsOf
          <| submodule (
            { config, ... }:
            {
              options = {
                package = mkPackageOption pkgs "rustic" { };

                environmentFile = mkOption {
                  type = nullOr str;
                  default = null;
                  description = "EnvironmentFile providing RUSTIC_REPOSITORY, RUSTIC_PASSWORD_FILE, OPENDAL_* etc.";
                };

                paths = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Paths to back up, passed to rustic as positional source args.";
                };

                exclude = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Glob patterns to exclude (written to an --exclude-file).";
                };

                extraBackupArgs = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Extra arguments passed to `rustic backup`.";
                };

                initialize = mkOption {
                  type = bool;
                  default = false;
                  description = "Run `rustic init` if the repository doesn't exist yet.";
                };

                pruneOpts = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Options for `rustic forget --prune`, run after backup.";
                  example = [
                    "--keep-daily 8"
                    "--keep-weekly 5"
                    "--keep-monthly 3"
                  ];
                };

                runCheck = mkOption {
                  type = bool;
                  default = config.checkOpts != [ ];
                  description = "Whether to run `rustic check` after backup/prune.";
                };

                checkOpts = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Options for `rustic check`.";
                };

                user = mkOption {
                  type = str;
                  default = "root";
                };

                timerConfig = mkOption {
                  type = nullOr (attrsOf unitOption);
                  default = {
                    OnCalendar = "daily";
                    Persistent = true;
                  };
                };
              };
            }
          );
      };

      config = {
        sops.secrets."rustic/password".sopsFile = ../secrets/services/rustic.yaml;

        assertions = mapAttrsToList (name: backup: {
          assertion = backup.paths != [ ] || backup.pruneOpts != [ ] || backup.checkOpts != [ ];
          message = "services.rustic.backups.${name} has nothing to do (no paths, pruneOpts, or checkOpts).";
        }) config.services.rustic.backups;

        myLib.mkRusticBackup =
          name: rest:
          {
            package = pkgs.rustic;
            environmentFile =
              toString
              <| pkgs.writeText "rustic-garage-env" ''
                RUSTIC_REPOSITORY="opendal:s3"
                RUSTIC_PASSWORD_FILE="${secrets."rustic/password".path}"

                OPENDAL_BUCKET="backups"
                OPENDAL_ROOT="/${hostName}/${name}"
                OPENDAL_ENDPOINT="http://${endpoint}"
                OPENDAL_REGION="${region}"

                AWS_PROFILE=${alias}
                AWS_SHARED_CREDENTIALS_FILE=${config.s3.credentialsFile}
                AWS_REGION=${region}
              '';
            initialize = true;
            pruneOpts = [
              "--keep-daily 8"
              "--keep-weekly 5"
              "--keep-monthly 3"
            ];
          }
          // rest;

        systemd.services = mapAttrs' (
          name: backup:
          let
            rusticCmd = getExe backup.package;
            excludeFile = optional (backup.exclude != [ ]) (
              pkgs.writeText "rustic-exclude-${name}" (concatStringsSep "\n" backup.exclude)
            );
            excludeFlags = optional (backup.exclude != [ ]) "--glob-file=${builtins.head excludeFile}";
            pathsQuoted = map escapeShellArg backup.paths;
            doBackup = backup.paths != [ ];
            cacheFlag = "--cache-dir \"$CACHE_DIRECTORY\"";
            pruneCmd = optional (
              backup.pruneOpts != [ ]
            ) "${rusticCmd} ${cacheFlag} forget --prune ${concatStringsSep " " backup.pruneOpts}";
            checkCmd = optional backup.runCheck "${rusticCmd} ${cacheFlag} check ${concatStringsSep " " backup.checkOpts}";
          in
          nameValuePair "rustic-backups-${name}" {
            restartIfChanged = false;
            wants = singleton "network-online.target";
            after = singleton "network-online.target";
            serviceConfig = {
              Type = "oneshot";
              User = backup.user;
              RuntimeDirectory = "rustic-backups-${name}";
              CacheDirectory = "rustic-backups-${name}";
              CacheDirectoryMode = "0700";
              PrivateTmp = true;
              ExecStart =
                optional doBackup "${rusticCmd} ${cacheFlag} backup ${
                  concatStringsSep " " (backup.extraBackupArgs ++ excludeFlags ++ pathsQuoted)
                }"
                ++ pruneCmd
                ++ checkCmd;
            }
            // optionalAttrs (backup.environmentFile != null) {
              EnvironmentFile = backup.environmentFile;
            };
            preStart = optionalString backup.initialize ''
              ${rusticCmd} ${cacheFlag} cat config > /dev/null || ${rusticCmd} init
            '';
          }
        ) config.services.rustic.backups;

        systemd.timers = mapAttrs' (
          name: backup:
          nameValuePair "rustic-backups-${name}" {
            wantedBy = singleton "timers.target";
            inherit (backup) timerConfig;
          }
        ) (filterAttrs (_: b: b.timerConfig != null) config.services.rustic.backups);

        environment.systemPackages = mapAttrsToList (
          name: backup:
          pkgs.writeShellScriptBin "rustic-${name}" ''
            set -a
            ${optionalString (backup.environmentFile != null) "source ${backup.environmentFile}"}
            set +a
            exec ${getExe backup.package} "$@"
          ''
        ) config.services.rustic.backups;
      };
    };
}
