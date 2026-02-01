{
  flake.modules.hjem.yazi =
    {
      pkgs,
      lib,
      isDesktop,
      ...
    }:
    let
      inherit (lib.modules) mkIf;
      inherit (lib.lists) singleton;

      toml = pkgs.formats.toml { };

      settings = {
        mgr = {
          ratio = [
            2
            2
            4
          ];
          show_hidden = true;
          show_symlink = false;
          scrolloff = 5;
        };

        preview = {
          wrap = "no";
          tab_size = 3;
          image_delay = 0;
          image_filter = "lanczos3";
          image_quality = 90;
        };

        input.cursor_blink = false;
      };
    in
    mkIf isDesktop {
      packages = singleton pkgs.yazi;

      xdg.config.files."yazi/yazi.toml".source = toml.generate "yazi-config.toml" settings;
    };
}
