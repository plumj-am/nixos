{
  flake.modules.nixos.docker-rootless =
    { pkgs, lib, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true; # Doesn't seem to work?
        extraPackages = [
          pkgs.iptables
          pkgs.nftables
        ];
        daemon.settings = {
          default-runtime = "youki";
          runtimes.youki.path = getExe pkgs.youki;
        };
      };

      boot.kernelModules = [
        "xt_addrtype"
        "iptable_nat"
        "ip_tables"
        "nf_nat"
      ];
    };
}
