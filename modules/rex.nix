{ self, ... }:
{
  flake.modules.nixos.desktop = self.modules.nixos.rex;
  flake.modules.nixos.rex =
    {
      inputs,
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton inputs.rex.nixosModules.default;

      environment.systemPackages =
        singleton
          inputs.rex.packages.${pkgs.stdenv.hostPlatform.system}.default;

      services.rex = {
        enable = true;

        extraListen = singleton "tailnet://:7297";
      };
    };
}
