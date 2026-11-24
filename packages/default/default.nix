{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.default =
        pkgs.writers.writeNuBin "nh" # nu
          ''
            def --wrapped main [...arguments] {
              $env.NH_FLAKE = "${self}"
              exec ${lib.meta.getExe pkgs.nh} ...$arguments
            }
          '';
    };
}
