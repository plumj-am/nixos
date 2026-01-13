{
  flake.modules.nixos.prometheus-node-exporter = {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "processes"
        "systemd"
        "hwmon"
      ];
      listenAddress = "[::]";
    };
  };
}
