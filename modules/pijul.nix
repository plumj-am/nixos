{
  flake.modules.common.pijul =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      hjem.extraModule =
        { config, ... }:
        {
          packages = singleton pkgs.pijul;

          xdg.config.files."pijul/config.toml" = {
            generator = pkgs.writers.writeTOML "pijul-config.toml";
            value = {
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
          };
        };
    };
}
