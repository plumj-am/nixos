{
  config.flake.modules.nixosModules.thunar =
    { pkgs, ... }:
    {
      # TODO: Might need desktop entry?
      environment.systemPackages = [
        pkgs.thunar
        pkgs.tumbler
      ];
    };
}
