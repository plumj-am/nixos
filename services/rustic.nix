{
  flake.services.rustic =
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
        anything
        ;
      inherit (lib.lists) optional singleton;

      inherit (config.networking) hostName;
      inherit (utils.systemdUtils.unitOptions) unitOption;

      cfg = config.services.rustic;
    in
    {
      options.helpers =
        mkOption {
          type = attrsOf anything;
          default = { };
          description = "Helper exports";
        }
        // {
          rustic = mkOption {
            type = attrsOf anything;
            default = { };
            description = "Rustic helper exports";
          };
        };

      options.services.rustic = {
        passwordFile = mkOption {
          type = nullOr str;
          default = null;
          description = "Path to a file containing the rustic repository password.";
        };

        credentialsFile = mkOption {
          type = nullOr str;
          default = null;
          description = "Path to an AWS shared credentials file.";
        };

        bucket = mkOption {
          type = str;
          default = "backups";
          description = "S3 bucket used for backups.";
        };

        endpoint = mkOption {
          type = str;
          description = "S3 endpoint host (without scheme).";
        };

        region = mkOption {
          type = str;
          description = "S3 region.";
        };

        alias = mkOption {
          type = str;
          description = "AWS profile alias used to look up credentials.";
        };

        backups = mkOption {
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
        ) cfg.backups;

        systemd.timers = mapAttrs' (
          name: backup:
          nameValuePair "rustic-backups-${name}" {
            wantedBy = singleton "timers.target";
            inherit (backup) timerConfig;
          }
        ) (filterAttrs (_: b: b.timerConfig != null) cfg.backups);

        environment.systemPackages = mapAttrsToList (
          name: backup:
          pkgs.writeShellScriptBin "rustic-${name}" ''
            set -a
            ${optionalString (backup.environmentFile != null) "source ${backup.environmentFile}"}
            set +a
            exec ${getExe backup.package} "$@"
          ''
        ) cfg.backups;
      };
    };
}
