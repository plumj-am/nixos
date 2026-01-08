{
  config.flake.modules.homeModules.gtk =
    { config, ... }:
    let
      packages = [ config.theme.gtk.package ];
    in
    {
      rum.misc.gtk = {
        inherit packages;
        enable = true;
        settings = {
          application-prefers-dark-theme = true;
          font-name = "${config.theme.font.sans.name} ${toString config.theme.font.size.small}";
          theme-name = config.theme.gtk.name;
          icon-theme-name = config.theme.icons.name;
        };
      };
    };

  config.flake.modules.nixosModules.gtk =
    {
      programs.dconf.enable = true;
    };
}
