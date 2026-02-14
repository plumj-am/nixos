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

      pijulConfig = {
        colors = "always";
        pager = "auto";
        unrecord_changes = 1;

        author = {
          name = "plumjam";
          full_name = "PlumJam";
          email = "pijul@plumj.am";
          key_path = "/home/jam/.ssh/id.pub";
        };
      };
    in
    {
      hjem.extraModules = singleton {
        packages = singleton pkgs.pijul;

        xdg.config.files."pijul/config.toml".source = toml.generate "pijul-config.toml" pijulConfig;
      };
    };
in
{
  flake.modules.nixos.pijul = pijulBase;
  flake.modules.darwin.pijul = pijulBase;
}
