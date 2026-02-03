{
  flake-file.inputs = {
    rio = {
      url = "github:raphamorim/rio/main";

      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
    };
  };

  # TODO: Configuration.
  # No point configuring yet because it still doesn't work for some reason.
  # flake.modules.hjem.rio =
  #   {
  #     pkgs,
  #     myLib,
  #     inputs,
  #     ...
  #   }:
  #   let
  #     inherit (myLib) mkDesktopEntry;
  #   in
  #   {
  #     packages = [
  #       inputs.rio.packages.${pkgs.stdenv.hostPlatform.system}.rio
  #       (mkDesktopEntry { inherit pkgs; } {
  #         name = "Zellij-Rio";
  #         exec = "rio -c ${pkgs.zellij}/bin/zellij";
  #       })
  #     ];
  #   };
}
