{
  config.flake.modules.nixosModules.qt =
    { config, ... }:
    let
      inherit (config) theme;
    in
    {
      qt = {
        enable = true;

        style = theme.qt.name;
      };
    };
}
