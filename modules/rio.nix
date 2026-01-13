{
  flake-file.inputs = {
    rio = {
      url = "github:raphamorim/rio/main";

      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
      inputs.rust-overlay.follows = "";
      inputs.systems.follows = "";
    };
  };

  # TODO: Configuration.
  # No point configuring yet because it still doesn't work for some reason.
  # flake.modules.hjem.rio =
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
