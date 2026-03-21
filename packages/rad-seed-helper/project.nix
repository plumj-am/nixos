{
  perSystem =
    {
      pkgs,
      ...
    }:
    let
      name = "rad-seed-helper";
      root = ./.;

      rad-seed-helper = pkgs.haskellPackages.developPackage {
        inherit name root;
      };
    in
    {
      packages = {
        inherit rad-seed-helper;
      };

      checks = {
        "${name}-hlint" =
          pkgs.runCommand "${name}-hlint-check"
            {
              nativeBuildInputs = [ pkgs.haskellPackages.hlint ];
            }
            ''
              hlint ${./.}
              touch $out
            '';

        "${name}-fmt" =
          pkgs.runCommand "fmt-check"
            {
              nativeBuildInputs = [
                pkgs.haskellPackages.fourmolu
                pkgs.haskellPackages.stylish-haskell
              ];
            }
            ''
              fourmolu --config ${root}/fourmolu.yaml --mode check --no-cabal ${root}/*.hs
              stylish-haskell --recursive ${root}/*.hs
              touch $out
            '';

        "${name}-cabal-fmt" =
          pkgs.runCommand "cabal-fmt-check"
            {
              nativeBuildInputs = [ pkgs.haskellPackages.cabal-fmt ];
            }
            ''
              cabal-fmt --check ${root}/rad-seed-helper.cabal --indent 4
              touch $out
            '';
      };

      devShells.haskell = pkgs.haskellPackages.shellFor {
        packages = _: [ rad-seed-helper ];

        buildInputs = with pkgs.haskellPackages; [
          cabal-fmt
          cabal-gild
          cabal-install
          fourmolu
          haskell-language-server
          hlint
          stylish-haskell
          weeder
        ];

        withHoogle = true;
      };
    };
}
