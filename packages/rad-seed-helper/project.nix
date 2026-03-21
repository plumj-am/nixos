{
  perSystem =
    {
      pkgs,
      config,
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

        "${name}-weeder" =
          pkgs.runCommand "${name}-weeder-check"
            {
              nativeBuildInputs = [ pkgs.haskellPackages.weeder ];
            }
            ''
              weeder ${root}
              touch $out
            '';

        "${name}-fmt" =
          pkgs.runCommand "fmt-check"
            {
              nativeBuildInputs = [ pkgs.haskellPackages.fourmolu ];
            }
            ''
              fourmolu --mode check ${root}/*.hs
              stylish-haskell --recursive ${root}/*.hs
              touch $out
            '';

        "${name}-cabal-gild" =
          pkgs.runCommand "cabal-gild-check"
            {
              nativeBuildInputs = [ pkgs.haskellPackages.cabal-gild ];
            }
            ''
              cabal-gild --input ${root}/rad-seed-helper.cabal --mode check
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
