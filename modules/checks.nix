{
  perSystem =
    { pkgs, ... }:
    {
      checks = {
        statix =
          pkgs.runCommand "statix-check"
            {
              nativeBuildInputs = [
                # For experimental pipe-operators support.
                (pkgs.statix.overrideAttrs rec {
                  src = pkgs.fetchFromGitHub {
                    owner = "oppiliappan";
                    repo = "statix";
                    rev = "43681f0da4bf1cc6ecd487ef0a5c6ad72e3397c7";
                    hash = "sha256-LXvbkO/H+xscQsyHIo/QbNPw2EKqheuNjphdLfIZUv4=";
                  };

                  cargoDeps = pkgs.rustPlatform.importCargoLock {
                    lockFile = src + "/Cargo.lock";
                    allowBuiltinFetchGit = true;
                  };
                })
              ];
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
              nativeBuildInputs = [ pkgs.deadnix ];
            }
            ''
              deadnix --fail ${../.}
              touch $out
            '';

        # Don't use legacy imports.
        nix-path =
          pkgs.runCommand "nix-path"
            {
              # nativeBuildInputs = [ pkgs.grep ];
            }
            ''
              ! grep -r "import <nixpkgs>" ${../.}/modules/ --exclude=checks.nix || exit 1
              ! grep -r "import <nixos>" ${../.}/modules/ --exclude=checks.nix || exit 1
              touch $out
            '';
      };
    };
}
