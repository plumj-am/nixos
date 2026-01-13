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
  #   { pkgs, config, ... }:
  #   let
  #     inherit (config.myLib) mkDesktopEntry;
  #   in
  #   {
  #     packages = [
  #       pkgs.rio
  #       (mkDesktopEntry { inherit pkgs; } {
  #         name = "Zellij-Rio";
  #         exec = "rio -c ${pkgs.zellij}/bin/zellij";
  #       })
  #     ];
  #   };
}
