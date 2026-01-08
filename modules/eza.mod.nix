{
  config.flake.modules.homeModules.eza =
    { pkgs, ... }:
    let
      package = pkgs.eza;
    in
    {
      programs.nushell.aliases = {
        ls  = "eza";
        sl  = "eza";
        ll  = "eza -la";
        la  = "eza -a";
        lsa = "eza -a";
        lsl = "eza -l -a";
      };

      packages = [ package ];
    };
}
