{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.tern-custom-rail-style =
        let
          manifest = pkgs.writers.writeTOML "custom-rail-style-plugin.toml" {
            schema = 1;
            id = "custom-rail-style";
            name = "tern-custom-rail-style";
            version = "0.1.0";
            description = "Drop the empty window-control band above the rail's tab strip and make tabs shorter.";

            window = "init.luau";
            styles = [ "tern-custom-rail-style.css" ];
          };

          entry =
            pkgs.writers.writeText "tern-custom-rail-style-init.luau" # luau
              ''
                -- The manifest's stylesheet does the work; no hook runs here but it's still needed.
              '';

          stylesheet =
            pkgs.writers.writeText "tern-custom-rail-style.css" # css
              ''
                html.lay-rail.tabs-v:not(.csd) {
                	--tn-rail-top: 0px;
                }

                html.lay-rail.tabs-v #sidebar > nav.tn-vt .nav-row {
                	height: 24px !important;
                	min-height: 24px !important;
                	padding-top: 0 !important;
                	padding-bottom: 0 !important;
                }
              '';
        in
        pkgs.runCommand "tern-custom-rail-style-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
          ln --symbolic ${stylesheet} "$out/tern-custom-rail-style.css"
        '';
    };
}
