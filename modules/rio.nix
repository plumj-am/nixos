let
  # TODO: Configuration.
  # No point configuring yet because it still doesn't work for some reason.
  rioBase =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (config.myLib) mkDesktopEntry;
      inherit (lib.lists) singleton;
    in
    {

      hjem.extraModules = singleton {
        packages = [
          inputs.rio.packages.${pkgs.stdenv.hostPlatform.system}.rio

          (mkDesktopEntry { inherit pkgs; } {
            name = "Zellij-Rio";
            exec = "rio -c ${pkgs.zellij}/bin/zellij";
          })
        ];
      };
    };
in
{
  flake-file.inputs = {
    rio = {
      url = "github:raphamorim/rio/main";

      inputs.nixpkgs.follows = "os";
      inputs.flake-parts.follows = "parts";
    };
  };

  flake.modules.nixos.rio = rioBase;
  flake.modules.darwin.rio = rioBase;
}
