{ self, ... }:
{
  flake.modules.nixos.gpu-unlock =
    { pkgs, config, ... }:
    let
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.gpu-unlock;
    in
    {
      # Built for the kernel this host actually boots.
      boot.extraModulePackages = [ (package.mkModule config.boot.kernelPackages.kernel) ];

      # The unlock has to run before nvidia binds the card, and it requests its
      # firmware right then, so both belong in the initrd.
      boot.initrd.kernelModules = [ "gpu_unlock" ];
      boot.initrd.extraFirmwarePaths = package.firmwarePaths;

      # `boot.initrd.kernelModules` becomes modules-load.d/nixos.conf, whose
      # order is the alphabet, so "gpu_unlock" only precedes the "nvidia" that
      # nixpkgs' facter graphics module loads on this host by coincidence of
      # naming, and udev coldplug can load nvidia on its own before
      # systemd-modules-load runs at all. A driver that binds first locks the
      # card until the next cold boot. Modprobe the unlock ahead of both
      # instead, and keep the modules-load entry above as the fallback.
      boot.initrd.systemd.services.gpu-unlock = {
        description = "Unlock Ampere cards before the NVIDIA driver binds them";
        wantedBy = [ "initrd.target" ];
        before = [
          "systemd-udevd.service"
          "systemd-modules-load.service"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.boot.initrd.systemd.package.kmod}/bin/modprobe gpu_unlock";
          RemainAfterExit = true;
        };
      };

      # Needed again after resume, when the cards are powered off and lose the
      # speed selectors.
      hardware.firmware = [ package.firmware ];

      # The module is inert without this opt-in. `all` unlocks every supported
      # card that no driver has bound yet.
      boot.kernelParams = [ "gpu_unlock.targets=all" ];
    };
}
