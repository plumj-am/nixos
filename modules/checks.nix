{ self, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.attrsets) mapAttrs' filterAttrs nameValuePair;
      inherit (lib.lists) elem singleton;

      sys = pkgs.stdenv.hostPlatform.system;

      # Evaluate NixOS configurations matching the current system e.g. x86_64-linux as checks.
      nixosMachines =
        mapAttrs' (
          name: nixosConfig: nameValuePair "nixos-${name}" nixosConfig.config.system.build.toplevel
        )
        <| filterAttrs (_: config: config.pkgs.stdenv.hostPlatform.system == sys) self.nixosConfigurations;

      # Evaluate packages as checks.
      # Need to fix IFD in rsh.
      blacklistPackages = [ ];
      packages =
        mapAttrs' (n: nameValuePair "package-${n}")
        <| filterAttrs (n: _: !(elem n blacklistPackages))
        <| self.packages.${sys} or { };
    in
    {
      checks = {
        statix =
          pkgs.runCommand "statix-check"
            {
              nativeBuildInputs = singleton pkgs.statix;
            }
            ''
              cat > statix.toml <<'EOF'
              disabled = [ "repeated_keys" ]
              EOF
              export STATIX_CONFIG=$(realpath statix.toml)
              statix check ${../.}
              touch $out
            '';

        deadnix =
          pkgs.runCommand "deadnix-check"
            {
              nativeBuildInputs = singleton pkgs.deadnix;
            }
            ''
              deadnix --fail ${../.}
              touch $out
            '';

        # TODO: Setup treefmt for yml, qml, etc. formatting.
        nixfmt =
          pkgs.runCommand "nixfmt"
            {
              nativeBuildInputs = singleton pkgs.nixfmt;
            }
            ''
              nixfmt --check ${../.}
              touch $out
            '';
      }
      // nixosMachines
      // packages;
    };
}
