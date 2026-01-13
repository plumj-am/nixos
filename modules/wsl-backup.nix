{
  flake.modules.hjem.wsl-backup =
    { lib, isWsl, ... }:
    let
      inherit (lib.modules) mkIf;
    in
    mkIf isWsl {
      files."wsl-backup.nu" = {
        executable = true;
        text = /* nu */ ''
          #!/usr/bin/env nu
          def log [msg: string, level: string = "INFO"] {
            let timestamp = (date now | format date '%Y-%m-%d %H:%M:%S')
            print $"[($timestamp)] ($level): ($msg)"
          }

          def main [] {
            log "Starting NixOS-WSL backup..."

            let nixos_host    = "pear"
            let github_repo   = "plumj-am/nixos"
            let windows_drive = "c"
            let windows_user  = "james"
            let windows_base  = $"/mnt/($windows_drive)/Users/($windows_user)"
            let backup_path   = $"($windows_base)/nixos-wsl-backup"
            let backup_file   = $"($backup_path)/nixos.wsl"

            log "Checking prerequisites..."

            if not ($windows_base | path exists) {
              log $"Windows mount not available at ($windows_base)" "ERROR"
              exit 1
            }

            try {
              ^mkdir --parents $backup_path
            } catch { |e|
              log $"Cannot create backup directory: ($e.msg)" "ERROR"
              exit 1
            }

            let temp_dir = try {
              ^mktemp -d
            } catch { |e|
              log $"Cannot create temp directory: ($e.msg)" "ERROR"
              exit 1
            }

            log "Prerequisites check passed"

            log "Cloning repository..."
            cd $temp_dir
            try {
              ^git clone https://github.com/($github_repo).git repo
              cd repo
            } catch { |e|
              log $"Git clone failed: ($e.msg)" "ERROR"
              ^rm -rf $temp_dir
              exit 1
            }

            log "Building system tarball..."
            try {
              ^sudo nix run .#nixosConfigurations.($nixos_host).config.system.build.tarballBuilder --accept-flake-config
            } catch { |e|
              log $"Tarball build failed: ($e.msg)" "ERROR"
              ^rm -rf $temp_dir
              exit 1
            }

            let tarball_path = "nixos.wsl"
            if not ($tarball_path | path exists) {
              log $"Could not find generated tarball at ($tarball_path)" "ERROR"
              ^rm -rf $temp_dir
              exit 1
            }
            log $"Found tarball: ($tarball_path)"

            log "Copying to backup location..."
            try {
              ^cp $tarball_path $backup_file
              log "Backup completed successfully!" "SUCCESS"
              log $"Backup located at: ($backup_file)"
            } catch { |e|
              log $"Copy failed: ($e.msg)" "ERROR"
              log $"Tarball available at: ($temp_dir)/repo/($tarball_path)" "WARN"
              ^rm -rf $temp_dir
              exit 1
            }

            ^rm -rf $temp_dir
            log "Cleanup completed"
          }
        '';
      };
    };

  flake.modules.nixos.wsl-backup =
    { pkgs, ... }:
    {
      systemd.services.nixos-wsl-backup = {
        description = "NixOS-WSL System Backup";

        serviceConfig = {
          Type = "oneshot";
          User = "root";
          ExecStart = "/home/jam/wsl-backup.nu";
        };

        path = with pkgs; [
          nix
          git
          nushell
        ];
      };

      systemd.timers.nixos-wsl-backup = {
        enable = true;
        description = "Run NixOS-WSL backup every 6 hours";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "4h";
          Persistent = true;
        };
      };
    };
}
