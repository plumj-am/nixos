{
  flake.modules.nixos.boot-optimise =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkForce mkIf mkMerge;
      inherit (config.networking) hostName;
    in
    {
      config = mkMerge [
        {
          # A custom target that activates 20s after multi-user.target.
          # Services pulled here start with a delay, freeing resources for
          # faster boot.
          systemd.targets."lazy-start" = {
            description = "Lazy-start target for non-critical services";
            requires = [
              "network.target"
              "sops-install-secrets.service"
            ];
          };

          systemd.timers."lazy-start" = {
            description = "Trigger lazy-start target after boot delay";
            wantedBy = singleton "multi-user.target";
            timerConfig = {
              OnBootSec = "20s";
              Unit = "lazy-start.target";
            };
          };

          # Move each service from multi-user.target -> lazy-start.target.
          systemd.services = {
            shed.wantedBy = mkForce <| singleton "lazy-start.target";
            nix-upload-processor.wantedBy = mkForce <| singleton "lazy-start.target";
            s3-setup.wantedBy = mkForce <| singleton "lazy-start.target";
            s3-credentials.wantedBy = mkForce <| singleton "lazy-start.target";
          };

          # zswap: in-RAM compressed swap. Configured via boot.zswap (kernel
          # params + sysfs watchers) — sysctls under vm.zswap.* don't exist on
          # modern kernels and would be silently ignored.
          boot.zswap = {
            enable = true;
            # lz4: fastest decompression, lowest latency (vs zstd default).
            compressor = "lz4";
            maxPoolPercent = 10;
          };

          # lz4 must be loaded before lockdown (kernel.modules_disabled=1) so
          # zswap can use it as compressor; crypto-request_module would fail
          # after boot. (boot.zswap adds it to initrd; keep it in
          # kernelModules too so it's available early.)
          boot.kernelModules = singleton "lz4";

          # Swappiness: lower means less aggressive swapping (desktop with NVMe).
          boot.kernel.sysctl = {
            "vm.swappiness" = 10;
            "vm.vfs_cache_pressure" = 50;
          };
        }

        # CI runner is not needed before login. Its docker jobs socket-activate
        # dockerd on first CLI use, so boot autostart is dropped.
        (mkIf (config.services.gitea-actions-runner.instances ? ${hostName} ? enable) {
          systemd.services."gitea-runner-${hostName}".wantedBy = mkForce <| singleton "lazy-start.target";
          virtualisation.docker.enableOnBoot = false;
        })
      ];
    };
}
