{ self, ... }:
{
  flake.modules.nixos.nuke = self.modules.nixos.nuke-webkitgtk;
  flake.modules.nixos.nuke-webkitgtk =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton filter;
    in
    {
      nixpkgs.overlays = singleton (
        _final: prev: {
          # protontricks only uses yad for its --gui mode's dialog boxes,
          # never the --html dialog type, but nixpkgs' yad hardcodes
          # --enable-html and unconditionally links webkitgtk_4_1. Build a
          # webkit-free yad just for protontricks rather than touching yad
          # itself, since other consumers may actually want --html.
          yad = prev.yad.overrideAttrs (old: {
            configureFlags = filter (f: f != "--enable-html") old.configureFlags;
            buildInputs = filter (dep: dep != pkgs.webkitgtk_4_1) old.buildInputs;
          });

          # rnnoise-plugin drags webkitgtk_4_1 into buildInputs purely because
          # JUCE's default plugin profile includes a WebBrowser module. The
          # built shared object has no UI, so we strip webkit and tell JUCE
          # to skip web.
          rnnoise-plugin = prev.rnnoise-plugin.overrideAttrs (old: {
            buildInputs = filter (p: (p.pname or "") != "webkitgtk") (old.buildInputs or [ ]);
            cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DJUCE_WEB_BROWSER=0" ];
          });
        }
      );
    };
}
