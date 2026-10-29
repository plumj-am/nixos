{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      # tern-rail-band: the rail's tab strip loses the band above it.
      #
      # In the Rail layout beside vertical tabs Tern keeps `--tn-rail-top`
      # (`html.lay-rail`) above the strip for its own window controls, which
      # `html.csd` draws 12px into that band, and it gives `#sidebar` the same
      # band plus 40px of padding. A host whose compositor draws no
      # decorations and whose Tern keeps its system title bar has no controls
      # there, so the band is empty space in the window's top-left corner.
      #
      # The variable feeds the strip's padding and the sidebar's, so zeroing
      # it moves the strip to the window edge and the tab list up after it,
      # and the strip keeps its drag region at the very top.
      #
      # Only rail + vertical tabs and only without CSD: a `.csd` window keeps
      # the band for the controls, and the horizontal rail (tabs-h) is left
      # alone, since its band was not measured.
      packages.tern-rail-band-plugin =
        let
          manifest = pkgs.writers.writeTOML "tern-rail-band-plugin.toml" {
            schema = 1;
            id = "rail-band";
            name = "tern-rail-band";
            version = "0.1.0";
            description = "Drop the empty window-control band above the rail's tab strip.";

            window = "init.luau";
            styles = [ "rail-band.css" ];
          };

          # A manifest needs an entry, and this plugin has nothing to run: the
          # style sheet is the whole plugin.
          entry =
            pkgs.writers.writeText "tern-rail-band-init.luau" # luau
              ''
                -- The manifest's styles sheet does the work; no hook runs here.
              '';

          stylesheet =
            pkgs.writers.writeText "tern-rail-band.css" # css
              ''
                /* Tern reserves --tn-rail-top above the rail's tab strip for
                   its own window controls, and pads the sidebar by the same
                   band plus 40px. With CSD off nothing sits in it. A CSD
                   window keeps it, because html.csd puts the controls there. */
                html.lay-rail.tabs-v:not(.csd) {
                	--tn-rail-top: 0px;
                }
              '';
        in
        pkgs.runCommand "tern-rail-band-plugin" { } ''
          mkdir --parents "$out"
          ln --symbolic ${manifest} "$out/plugin.toml"
          ln --symbolic ${entry} "$out/init.luau"
          ln --symbolic ${stylesheet} "$out/rail-band.css"
        '';
    };
}
