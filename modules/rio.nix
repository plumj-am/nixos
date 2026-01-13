{
  # TODO: Configuration.
  # No point configuring yet because it still doesn't work for some reason.
  # config.flake.modules.hjem.rio =
  #   { pkgs, ... }:
  #   {
  #     packages = [
  #       pkgs.rio
  #       (pkgs.writeTextFile {
  #         name = "zellij-rio";
  #         destination = "/share/applications/zellij-rio.desktop";
  #         text = ''
  #           [Desktop Entry]
  #           Name=Zellij Rio
  #           Icon=rio
  #           Exec=rio -e ${pkgs.zellij}/bin/zellij
  #           Terminal=false
  #         '';
  #       })
  #     ];
  #   };
}
