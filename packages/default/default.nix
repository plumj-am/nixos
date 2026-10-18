{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.meta) getExe;

      # pkgs.nh bakes its nom PATH prefix from the `nix-output-monitor`
      # argument, so the swap must go through `override`; `overrideAttrs`
      # cannot reach it.
      nh =
        getExe
        <| pkgs.nh.override {
          nix-output-monitor = inputs.grove.packages.${pkgs.stdenv.hostPlatform.system}.nom-rs;
        };
    in
    {
      packages.default =
        pkgs.writers.writeNuBin "nh" # nu
          ''
            def --wrapped main [...arguments] {
              $env.NH_FLAKE = "${self}"
              exec ${nh} ...$arguments
            }
          '';
    };
}
