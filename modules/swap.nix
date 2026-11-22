{ self, ... }:
{
  flake.nixosModules.server = self.nixosModules.swapfile;
  flake.nixosModules.swapfile =
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

      cfg = config.systemInfo.disks;
    in
    {
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

  flake.nixosModules.desktop = self.nixosModules.swap-partition;
  flake.nixosModules.swap-partition =
    { lib, config, ... }:
    let
      inherit (lib.lists) singleton;

      cfg = config.systemInfo.disks;
    in
    {
      config = {
        boot.zswap.enable = true;
        swapDevices = singleton {
          device = cfg.swap.partition.path;
        };
      };
    };
}
