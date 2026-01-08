{
  config.flake.modules.nixosModules.zram-swap =
    {
      zramSwap.enable = true;
    };
}
