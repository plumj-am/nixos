{
  flake.services.rustic =
    {
      pkgs,
      lib,
      utils,
      config,
      ...
    }:
    let
      inherit (lib.attrsets)
        filterAttrs
        mapAttrs'
        mapAttrsToList
        nameValuePair
        optionalAttrs
        ;
      inherit (lib.lists) optional singleton;
      inherit (lib.meta) getExe;
      inherit (lib.options) mkOptionNullOr mkOptionOf mkPackageOption;
      inherit (lib.strings) concatStringsSep escapeShellArg optionalString;
      inherit (lib.types)
        attrsOf
        bool
        listOf
        nullOr
        str
        submodule
        ;
      inherit (utils.systemdUtils.unitOptions) unitOption;

      cfg = config.services.rustic;
    in
    {
      options.services.rustic = {
        passwordFile = mkOptionNullOr str {
          description = "Path to a file containing the rustic repository password.";
        };

        credentialsFile = mkOptionNullOr str {
          description = "Path to an AWS shared credentials file.";
        };

        bucket = mkOptionOf str {
          default = "backups";
          description = "S3 bucket used for backups.";
        };

        endpoint = mkOptionOf str {
          description = "S3 endpoint host (without scheme).";
        };

        region = mkOptionOf str {
          description = "S3 region.";
        };

        alias = mkOptionOf str {
          description = "AWS profile alias used to look up credentials.";
        };

        backups =
          mkOptionOf
            (
              attrsOf
              <| submodule (
                { config, ... }:
                {
                  options = {
                    package = mkPackageOption pkgs "rustic" { };

                    environmentFile = mkOptionNullOr str {
                      description = "EnvironmentFile providing RUSTIC_REPOSITORY, RUSTIC_PASSWORD_FILE, OPENDAL_* etc.";
                    };

                    paths = mkOptionOf (listOf str) {
                      description = "Paths to back up, passed to rustic as positional source args.";
                    };

                    exclude = mkOptionOf (listOf str) {
                      default = [ ];
                      description = "Glob patterns to exclude (written to an --exclude-file).";
                    };

                    extraBackupArgs = mkOptionOf (listOf str) {
                      default = [ ];
                      description = "Extra arguments passed to `rustic backup`.";
                    };

                    initialize = mkOptionOf bool {
                      default = false;
                      description = "Run `rustic init` if the repository doesn't exist yet.";
                    };

                    pruneOpts = mkOptionOf (listOf str) {
                      default = [ ];
                      description = "Options for `rustic forget --prune`, run after backup.";
                      example = [
                        "--keep-daily 8"
                        "--keep-weekly 5"
                        "--keep-monthly 3"
                      ];
                    };

                    runCheck = mkOptionOf bool {
                      default = config.checkOpts != [ ];
                      description = "Whether to run `rustic check` after backup/prune.";
                    };

                    checkOpts = mkOptionOf (listOf str) {
                      default = [ ];
                      description = "Options for `rustic check`.";
                    };

                    user = mkOptionOf str {
                      default = "root";
                    };

                    timerConfig = mkOptionOf (nullOr <| attrsOf unitOption) {
                      default = {
                        OnCalendar = "daily";
                        Persistent = true;
                      };
                    };
                  };
                }
              )
            )
            {
              default = { };
              description = "Periodic backups to create with rustic.";
            };
      };

      config = {
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
            # `cat config` fails both when the repository is absent and when the
            # backend cannot read it. Running `init` on the second case replaces
            # the key file and turns every stored snapshot into undecryptable
            # garbage, so a repository that this host has already seen is never
            # re-initialised, no matter what the backend reports.
            preStart = optionalString backup.initialize ''
              if ${rusticCmd} ${cacheFlag} cat config > /dev/null; then
                touch "$CACHE_DIRECTORY/repository-initialised"
              elif [ -e "$CACHE_DIRECTORY/repository-initialised" ] \
                || [ -n "$(find "$CACHE_DIRECTORY" -mindepth 1 -maxdepth 1 -type d -print -quit)" ]; then
                echo "rustic: the repository is not readable and already holds data; refusing to re-initialise it" >&2
                exit 1
              else
                ${rusticCmd} init
                touch "$CACHE_DIRECTORY/repository-initialised"
              fi
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
