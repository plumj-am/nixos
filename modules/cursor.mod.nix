{
  config.flake.modules.nixosModules.cursor =
    { pkgs, ... }:
    let
      package = pkgs.bibata-cursors;
    in
    {
      environment.systemPackages = [ package ];

      environment.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE  = "24";
      };
    };
}
