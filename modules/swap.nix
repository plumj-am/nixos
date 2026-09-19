{
  flake.modules.nixos.swapfile =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe';
      inherit (lib.modules) mkIf mkMerge;
      inherit (lib.options) mkOption;
      inherit (lib.types) int nullOr str;

      cfg = config.systemInfo.disks;
    in
    {
      options.systemInfo.disks = {
        swap = {
          file = {
            path = mkOption {
              type = str;
              default = "/swapfile";

            };
            size = mkOption {
              type = nullOr int;
              default = null;
            };
          };
        };
      };

      config = mkMerge [
        {
          boot.zswap.enable = true;
          swapDevices = singleton {
            device = cfg.swap.file.path;
          };
        }
        (mkIf (cfg.swap.file.size != null) {
          systemd.services.create-swapfile =
            let
              swapDevUnit = "swap-${lib.replaceStrings [ "/" ] [ "-" ] cfg.swap.file.path}.swap";
            in
            {
              description = "Create swapfile";
              before = [ swapDevUnit ];
              wantedBy = [ swapDevUnit ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script =
                let
                  path = cfg.swap.file.path;
                  size = cfg.swap.file.size;
                in
                ''
                  if ! test -f "${path}"; then
                    ${getExe' pkgs.util-linux "fallocate"} -l ${toString size}M "${path}"
                    ${getExe' pkgs.uutils-coreutils-noprefix "chmod"} 0600 "${path}"
                    ${getExe' pkgs.util-linux "mkswap"} "${path}"
                  else
                    echo "${path}: swapfile already exists, skipping creation"
                  fi
                '';
            };
        })
      ];
    };
  flake.modules.nixos.swap-partition =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.options) mkOption;
      inherit (lib.types) str;

      cfg = config.systemInfo.disks;
    in
    {
      options.systemInfo.disks = {
        swap.partition = {
          size = mkOption {
            type = str;
            default = "34G";
          };
          path = mkOption {
            type = str;
            default = "/dev/disk/by-label/swap";
          };
        };
        diskDevice = mkOption {
          type = str;
          default = "/dev/nvme0n1";
        };
      };

      config = {
        boot.zswap.enable = true;
        swapDevices = singleton {
          device = cfg.swap.partition.path;
        };
      };
    };
}
