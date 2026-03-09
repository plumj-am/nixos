let
  pijulBase =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;

      toml = pkgs.formats.toml { };
    in
    {
      hjem.extraModules = singleton (
        { config, ... }:
        {
          packages = singleton pkgs.pijul;

          xdg.config.files."pijul/config.toml".source = toml.generate "pijul-config.toml" {
            colors = "always";
            pager = "auto";
            unrecord_changes = 1;

            author = {
              name = "plumjam";
              full_name = "PlumJam";
              email = "pijul@plumj.am";
              key_path = "${config.directory}/.ssh/id.pub";
            };
          };
        }
      );
    };
in
{
  flake.modules.nixos.pijul = pijulBase;
  flake.modules.darwin.pijul = pijulBase;
}
